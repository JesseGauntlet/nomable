from fastapi import FastAPI, UploadFile, File
from typing import List
import uvicorn

app = FastAPI(title="FoodTok API")

# Sample data structure for the feed
fake_feed = [
    {
        "id": "1",
        "user_id": "user1",
        "video_url": "sample_video_1.mp4",
        "description": "Delicious homemade pasta!",
        "likes": 1000,
        "comments": 50
    },
    {
        "id": "2",
        "user_id": "user2",
        "video_url": "sample_video_2.mp4",
        "description": "Quick and easy breakfast recipe",
        "likes": 800,
        "comments": 30
    },
    {
        "id": "3",
        "user_id": "user3",
        "video_url": "sample_video_3.mp4",
        "description": "Spicy Korean BBQ tacos fusion! 🌮🔥",
        "likes": 2500,
        "comments": 120
    },
    {
        "id": "4",
        "user_id": "user4",
        "video_url": "sample_video_4.mp4",
        "description": "5-minute sushi bowl hack 🍣",
        "likes": 1500,
        "comments": 75
    },
    {
        "id": "5",
        "user_id": "user5",
        "video_url": "sample_video_5.mp4",
        "description": "Ultimate chocolate lava cake dessert 🍫",
        "likes": 3000,
        "comments": 200
    }
]

@app.get("/")
async def root():
    """Root endpoint to verify API is running"""
    return {"message": "Welcome to FoodTok API"}

@app.get("/feed")
async def get_feed() -> List[dict]:
    """Get the current feed of food videos"""
    return fake_feed

@app.post("/upload")
async def upload_video(file: UploadFile = File(...)):
    """Handle video upload"""
    # In a real implementation, we would:
    # 1. Validate the file is a video
    # 2. Process the video (compression, thumbnails, etc.)
    # 3. Store it in cloud storage
    # 4. Update database with metadata
    return {
        "filename": file.filename,
        "status": "Video uploaded successfully"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 