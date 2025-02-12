# AI Product Requirements Document

> **Context**:  
> This document describes how we will integrate AI features into our video-sharing food app. Notably, we'll:  
> 1. Generate tags and descriptions from uploaded food videos.  
> 2. Use those tags and descriptions to generate and cache recipes.  
> 3. Combine location data with tags and descriptions to generate restaurant recommendations.

---

## 1. Overview

### 1.1 Goal
- Automate the process of tagging and describing food videos using an AI model (initially **Gemini 2.0**).  
- Provide both **recipe recommendations** (when swiping left) and **restaurant suggestions** (when swiping right).

### 1.2 Background
- Users can toggle a switch on the video upload screen to enable AI-generated metadata.  
  - If enabled, once the user uploads a video, our **Cloud Function** calls the AI API to process the video and returns:  
    1. **Tags**: Set of label(s) for the food items.  
    2. **Description**: A short textual summary of what's in the video.  
 
- Our app workflow hinges on these AI-driven fields for deeper personalization in daily usage.

---

## 2. Detailed Feature Breakdown

### 2.1 AI Video Analysis
1. **Input**:  
   - The user's uploaded video.  
   - (Optionally) The user's location for better restaurant recommendations.

2. **Process**:  
   - **Gemini 2.0** (or a model set in a "pluggable AI" approach) extracts:  
     - All identifiable foods and relevant tags.  
     - A short textual description that summarizes the content.  
   - **Cloud Function** handles the request, orchestrating the AI calls, and returning structured data.  

3. **Output**:  
   - A JSON payload with:  
     - `tags` (array of strings)  
     - `description` (string)  
     - Potential `confidence_scores` (for each tag) if needed  

### 2.2 Tag & Description Storage 
- **Database**:  
  - Store the AI-generated tags and description in the `posts` document.  
  - This data can be updated or overwritten if the user manually edits tags or description.

- **Caching Mechanism**:  
  - Because the recipe or restaurant suggestions rely on the AI's metadata:  
    - We can store a "recipe recommendation" object or "restaurant recommendation" object in cache or a separate column for quick retrieval.  
    - Ensures consistent results for the same user and same video, avoiding repeated AI calls.  

### 2.3 Restaurant Recommendation Flow (Swipe Right)
1. **Trigger**: User swipes right on a video.  
2. **Process**:  
   - The app retrieves the stored tags and location.  
   - A **Cloud Function** call fetches recommended restaurants from an external API (e.g., Yelp, Google Places) using the stored tags and location.  
3. **Display**:  
   - Show a list of suggested restaurants in-app.  

### 2.4 Recipe Recommendation Flow (Swipe Left)
1. **Trigger**: User swipes left on a video.  
2. **Process**:  
   - We retrieve the AI-generated tags/description.  
   - A **recipe generation module** (or integration with a recipe database + the user's preferences) generates or fetches the relevant recipe.  
3. **Display**:  
   - Show the associated recipe in-app:  
     - Title, ingredients, steps, and optional user ratings if available.  

---

## 3. Implementation Details

### 3.1 AI Model Abstraction
- **Pluggable AI Approach**:  
  - We design the interface so we can switch from **Gemini 2.0** to another model without refactoring.  
  - All AI calls route through a single `aiProcessor` function or module.

### 3.2 Cloud Functions Architecture
- **Upload Trigger**:  
  1. The user toggles the "AI Generate" switch on the upload screen.  
  2. On video upload, a function `generateVideoAIData(videoId, userId, location)` is invoked.  
  3. This function:  
     - Calls **Gemini 2.0** with the video data.  
     - Processes and returns tags + description.  
     - Caches recommendations if possible (or can be done on demand).

- **Swipe Action Trigger**:  
  - Swiping right or left calls `getRestaurantRecommendations()` or `getRecipeRecommendations()`.  
  - Minimizes repeated AI queries by using the stored tags/description.  

### 3.3 Data Models (Firestore Integration)
This section aligns our AI data requirements with our existing Firestore schema as detailed in `database_schema.md`.

**Posts** (`/posts/{postId}`):
  - **userId**: string – Reference to the owner (matches `/users/{userId}`).
  - **mediaUrl**: string – URL to the video or image.
  - **mediaType**: string – "video" or "image".
  - **description**: string – User-provided caption; can be supplemented or replaced by AI-generated description.
  - **foodTags**: array of strings – General food tags (pre-existing), which may include AI-suggested items.
  - **recipe_recommendation** (optional): JSON object or reference – Contains generated recipe details.
  - **restaurant_recommendation** (optional): JSON object or reference – Contains AI-driven restaurant suggestions based on the combination of food tags and location.
  - **location**: GeoPoint – Either provided by the post or derived from `/users/{userId}`, used for location-based recommendations.
  - **swipeCounts**: map – e.g., { left: 12, right: 30 }
  - **heartCount**: number
  - **bookmarkCount**: number
  - **dietary_flags**: array of strings – AI-detected dietary considerations
  - **createdAt**: timestamp

**Users** (`/users/{userId}`):
  - Contains standard profile fields (e.g., name, email, profilePictureUrl).
  - **location**: GeoPoint – Crucial for fetching nearby restaurant recommendations.
  - Additional subcollections such as `friends`, `bookmarks`, and `preferenceHistory` support extended features.

**Interactions** (`/interactions/{interactionId}`):
  - **userId**: string
  - **postId**: string
  - **type**: string // e.g., "swipe", "heart", "bookmark"
  - **swipeDirection**: string // "left" (recipe), "right" (restaurant)
  - **ai_generated**: boolean // whether this interaction was with AI-enhanced content
  - **timestamp**: timestamp

### 3.4 Performance & Edge Cases
- **Performance**:
  - Large video uploads might require chunk uploads and background processing to avoid timeouts.  
  - AI calls are asynchronous, so we must handle fallback behavior if AI processing fails.  

- **Edge Cases**:  
  1. User toggles AI off → no AI calls.  
  2. The app can't detect foods reliably (e.g. obscure meal) → AI might return minimal or partial tags.  
  3. Location not available → skip restaurant suggestions.  