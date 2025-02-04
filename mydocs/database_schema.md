Below is one way to “map out” your Firestore schema for the food‐video app. There’s no single “correct” answer—Firestore is flexible—but the following design organizes your data into collections and (where helpful) subcollections so that you can:

- Store users and their friends, preferences, swipes, bookmarks, and historical snapshots (for graphs)
- Keep all “food posts” (photos/videos) globally queryable (for feeds)
- Record user–post interactions (swipes, hearts, bookmarks)
- Support group “consensus” sessions (with per‑group preference history)
- Maintain catalog data for recipes and restaurants

Below is an example structure with example fields. (You can adjust field names, types, and nesting to suit your needs.) 

---

## **Firestore Collections & Documents**

### **1. Users**

Each user’s document stores profile info, friend lists, and may include “summary” preference data. You can also add subcollections for things like friends, bookmarks, swipes, or historical snapshots.

```
/users/{userId} (Document)
  • username: string
  • email: string
  • profilePictureUrl: string
  • bio: string
  • createdAt: timestamp
  • location: GeoPoint        // (for local restaurant recommendations)
  • currentCraving: string    // (the food tag most recently “swiped” or hearted)
  • foodPreferences: map      // e.g., { "pizza": 42, "sushi": 15, … } – aggregated score

  // Option 1: Storing friends as an array (if list sizes are small)
  • friends: array of userIds

  // Option 2: OR a dedicated subcollection for richer friend info
  └─ /users/{userId}/friends/{friendUserId} (Document)
         - friendId: string        // redundant with document id
         - friendName: string
         - friendProfilePictureUrl: string
         - addedAt: timestamp
```

#### **User Subcollections**

- **Preference History** (to graph changes over time)
  ```
  /users/{userId}/preferenceHistory/{snapshotId} (Document)
    • date: timestamp
    • preferences: map        // e.g., { "pizza": 38, "burger": 20, … }
  ```
- **Bookmarks** (user’s saved posts)
  ```
  /users/{userId}/bookmarks/{bookmarkId} (Document)
    • postId: string
    • addedAt: timestamp
  ```
- **Swipes/Interactions (optional)** (to log each swipe that trains the ML)
  ```
  /users/{userId}/swipes/{swipeId} (Document)
    • postId: string
    • swipeType: string       // "left", "right", "up"
    • hearted: boolean        // if the user also tapped the heart icon
    • timestamp: timestamp
  ```

---

### **2. Posts (Food Videos & Images)**

All food “posts” are stored in a global collection so that you can easily build feeds (for all users, friends, or matching preferences). Each post is tagged with one or more food items.

```
/posts/{postId} (Document)
  • userId: string              // Reference to the owner (from /users)
  • mediaUrl: string            // URL to video or image
  • mediaType: string           // "video" or "image"
  • description: string         // Optional caption or details
  • foodTags: array of strings  // E.g., ["pizza", "pasta"]
  • createdAt: timestamp
  • swipeCounts: map            // e.g., { left: 12, right: 30, up: 5 }
  • heartCount: number
  • bookmarkCount: number
  • location: GeoPoint          // (optional: if location tagging is desired)
```

*Indexes:*  
– Make sure to index **foodTags** and **createdAt** for efficient feed queries (e.g. “latest posts with tag ‘sushi’”).

---

### **3. Interactions**  
_(Optional)_ You can also log each user’s action on posts in a separate collection (especially useful for analytics or training the ML model).

```
/interactions/{interactionId} (Document)
  • userId: string
  • postId: string
  • type: string         // e.g., "swipe", "heart", "bookmark"
  • swipeDirection: string  // (if type == "swipe") e.g., "left", "right", "up"
  • timestamp: timestamp
```

---

### **4. Groups (for Consensus Sessions)**

Groups let users come together to compare their current cravings and vote (with vetoes) on what to eat together.

```
/groups/{groupId} (Document)
  • name: string                 // Group name
  • createdBy: string            // User ID of the creator
  • createdAt: timestamp
  • members: array of strings    // List of user IDs; alternatively, store richer objects if needed
  • currentConsensusFood: string // Food tag currently topping the vote/consensus
  • vetoes: map                  // e.g., { userId1: true, userId2: false } (tracks if a member has used their veto)
```

#### **Group Subcollections**

- **Preference History** (to graph group trends)
  ```
  /groups/{groupId}/preferenceHistory/{snapshotId} (Document)
    • date: timestamp
    • preferences: map          // Aggregated, e.g., { "sushi": 25, "burger": 18 }
  ```
- (Optionally, you might include a chat/messages subcollection if group communication is desired.)

---

### **5. Recipes**

Store recipes that match food tags so you can recommend them based on user and group cravings.

```
/recipes/{recipeId} (Document)
  • name: string
  • description: string
  • ingredients: array of strings
  • instructions: string or array of steps
  • foodTags: array of strings   // E.g., ["pasta", "tomato"]
  • imageUrl: string
  • createdAt: timestamp
  • source: string                // (Optional: author or reference)
```

---

### **6. Restaurants**

Similarly, store restaurant data (possibly imported from a third‑party API) so that users get location‑based recommendations.

```
/restaurants/{restaurantId} (Document)
  • name: string
  • address: string
  • location: GeoPoint
  • foodTags: array of strings    // E.g., ["sushi", "ramen"]
  • imageUrl: string
  • rating: number
  • cuisine: string               // (Optional: type of cuisine)
  • createdAt: timestamp
```

---

### **7. (Optional) FoodItems**

You might want a “catalog” of food tags (e.g., pizza, burger) for analytics or trending lists.

```
/foodItems/{foodItemId} (Document)
  • name: string
  • totalPosts: number      // How many posts have this tag
  • trendingScore: number   // Custom metric for popularity
  • lastUpdated: timestamp
```

---

## **How This Schema Supports Your User Stories**

1. **Posting & Viewing Food Videos/Images:**  
   – When a user takes a picture/video, a new document is added to `/posts` (with its foodTags), and the user’s profile (under `/users/{userId}`) can reference it (or simply query for posts with that userId).  
   
2. **Friends List:**  
   – Each user’s document (or subcollection `/users/{userId}/friends`) stores the friend list.  
   
3. **Swiping/Preference Learning:**  
   – User interactions (swipes, hearts, bookmarks) are recorded either as subcollections or in the global `/interactions` collection.  
   – Aggregated scores (in the user doc’s `foodPreferences` field or via periodic snapshots in `/users/{userId}/preferenceHistory`) help tailor the feed.  
   
4. **Group Consensus:**  
   – Groups are stored under `/groups`, with fields for members, current consensus, and veto tracking.  
   – Each group can maintain a history (in `/groups/{groupId}/preferenceHistory`) for graphs.  
   
5. **Graphs Over Time:**  
   – Both users and groups have `preferenceHistory` subcollections where you can store snapshots (e.g., daily) of their food preference scores.  
   
6. **Feed Curation:**  
   – You query `/posts` by foodTags, ordering by `createdAt` so that users see a mix of posts that match their personal and/or group preferences.  
   – The bookmarks subcollection (under `/users`) lets users view saved posts, and related posts can be queried by matching foodTags.  
   
7. **Restaurant & Recipe Recommendations:**  
   – The `/restaurants` and `/recipes` collections store items tagged with food items so that you can recommend items that match the current cravings of the user or group.

---

## **Additional Considerations**

- **Indexes:** In Firestore, you’ll likely need composite indexes (e.g., on `foodTags` and `createdAt`) for fast queries on the posts feed.  
- **Data Duplication vs. Query Efficiency:** Sometimes storing “aggregated” fields (like counts in `/posts` or summary preferences in `/users`) can reduce read operations; just plan for how and when you update them.  
- **Security Rules:** Design your Firestore security rules so that users can only modify their own data (and groups they belong to) while still allowing read access where appropriate.  
- **Offline & Real-Time Updates:** Firestore’s real‑time listeners can be attached to subcollections (like swipes or preferenceHistory) so that graphs and feeds update live.

---

This schema should give you a solid starting point for implementing your TikTok‑like food app with Firebase Firestore. You can iterate on this design as you prototype features and refine your data access patterns.