import os
import json
from google.cloud import storage
from google.cloud import secretmanager
from google.cloud import firestore
from google import genai
import functions_framework

# Initialize clients
storage_client = storage.Client()
firestore_client = firestore.Client()
secrets_client = secretmanager.SecretManagerServiceClient()

def get_gemini_key():
    """Retrieve Gemini API key from Secret Manager."""
    name = f"projects/{os.environ.get('GOOGLE_CLOUD_PROJECT')}/secrets/Gemini/versions/latest"
    response = secrets_client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

def analyze_with_gemini(video_url):
    """Process video directly with Gemini Vision API using GCS URL."""
    api_key = get_gemini_key()
    client = genai.Client(api_key=api_key)
    model = client.models.get_model('gemini-2.0-flash')
    
    # Create video input using GCS URL
    video_part = genai.FileData(file_uri=video_url, mime_type="video/mp4")
    
    prompt = """
    Video analysis, returning primary food tags (e.g. pizza, and or italian,
    but not dough or tomato sauce), detailed description of the food in the
    video, quantified ingredients, detailed step by step recipe with
    quantified ingredient usage, and content moderation
    (if topic is_food_related, or topic is_nsfw, also add a "reason"
    field that states why content moderation failed).

    Example JSON structure for reference:

    Format your response as JSON with these fields:
    {
        "video_id": "unique_video_identifier",
        "topic": "food_related", 
        "primary_food_tags": [
            "pizza",
            "italian"
        ],
        "detailed_food_description": "A pepperoni pizza with a thick crust, topped with mozzarella cheese and sliced pepperoni.  Appears to be baked in a home oven.",
        "quantified_ingredients": [
            {"ingredient": "pizza dough", "quantity": "500g"},
            {"ingredient": "tomato sauce", "quantity": "200ml"},
            {"ingredient": "mozzarella cheese", "quantity": "300g"},
            {"ingredient": "pepperoni", "quantity": "150g"},
            {"ingredient": "olive oil", "quantity": "1 tbsp"},
            {"ingredient": "dried oregano", "quantity": "1 tsp"}
        ],
        "detailed_step_by_step_recipe": [
            {"step": 1, "instruction": "Preheat oven to 220°C (425°F)."},
            {"step": 2, "instruction": "Stretch or roll out the pizza dough to a 12-inch circle."},
            {"step": 3, "instruction": "Brush the dough with 1 tbsp of olive oil."},
            {"step": 4, "instruction": "Spread 200ml of tomato sauce evenly over the dough."},
            {"step": 5, "instruction": "Sprinkle 300g of mozzarella cheese over the sauce."},
            {"step": 6, "instruction": "Arrange 150g of pepperoni slices on top of the cheese."},
            {"step": 7, "instruction": "Sprinkle 1 tsp of dried oregano over the pizza."},
            {"step": 8, "instruction": "Bake for 15-20 minutes, or until the crust is golden brown and the cheese is melted and bubbly."},
            {"step": 9, "instruction": "Let cool slightly before slicing and serving."}
        ],
        "content_moderation": {
            "is_food_related": true,
            "is_nsfw": false,
            "reason": null
        }
    }
    """
    
    response = model.generate_content([prompt, video_part])
    try:
        return json.loads(response.text)
    except json.JSONDecodeError:
        return {"tags": [], "description": "Failed to analyze video"}

@functions_framework.cloud_event
def process_video(cloud_event):
    """Cloud Function triggered by video upload to storage."""
    # Gen2 functions receive CloudEvents
    if cloud_event.type != "google.cloud.storage.object.v1.finalized":
        return
    
    # The data field contains the Cloud Storage event data
    file_data = cloud_event.data
    
    # Skip if not a video file
    if not file_data["contentType"].startswith("video/"):
        print("Not a video file, skipping")
        return
        
    metadata = file_data.get("metadata", {})
    if metadata.get("useAI") != "true" or not metadata.get("postId"):
        print("Skipping AI processing, useAI =", metadata.get("useAI"),
               "postId =", metadata.get("postId"))
        return
    
    try:
        # Generate GCS URL
        video_url = f"gs://{file_data['bucket']}/{file_data['name']}"
        
        # Process with Gemini
        ai_results = analyze_with_gemini(video_url)
        
        # Update Firestore
        post_ref = firestore_client.collection("posts").document(metadata["postId"])
        post_ref.update({
            "foodTags": ai_results.get("primary_food_tags", []),
            "description": ai_results.get("detailed_food_description", ""),
            "recipe": ai_results.get("detailed_step_by_step_recipe", []),
            "ingredients": ai_results.get("quantified_ingredients", []),
            "ai_processed": True,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })
        
    except Exception as e:
        print(f"Error: {str(e)}")
        if metadata.get("postId"):
            firestore_client.collection("posts").document(metadata["postId"]).update({
                "ai_processed": False,
                "ai_error": str(e),
                "updatedAt": firestore.SERVER_TIMESTAMP
            })