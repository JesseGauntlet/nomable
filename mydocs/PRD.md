# Formal Product Requirements Document (PRD)

## 1. Overview

This document outlines the requirements, scope, and architecture for a video‐scrolling food app. The app's main goal is to capture both short‐term and long‐term user cravings, enabling frictionless personal recommendations and group consensus. The stack will leverage Flutter for cross‐platform UI, a Python‐based backend, and Firebase for authentication and data synchronization.

---

## 2. Objectives

1. **Cravings & Preferences Tracking**  
   - Users swipe through short videos of food (similar to TikTok) to indicate current cravings.  
   - Longer‐term preferences are tracked via a "heart" or "like" icon.  
   - Bookmarks ("want to try later") enable discovery and reminder functionalities.

2. **Group Consensus**  
   - Users can form groups. The system displays each member's highest cravings and computes the top food items the group collectively craves.  
   - The group can veto one item at a time, cycling through the next best choice.  
   - If all items are vetoed, the app can prompt group members to update or expand their swipes.

3. **Recommendations**  
   - **Restaurant Recommendations**: Suggest nearby restaurants that serve the top‐craved dish.  
   - **Recipe Recommendations**: Suggest recipes that align with the user's or a group's top cravings.  
   - **Personal Feed Variety**: Show content that aligns with the user's historical tastes but also introduce novelty.

4. **Data & Analytics**  
   - Capture user and group craving data over time to observe trends and shifts.  
   - Track broad food categories initially (pizza, sushi, burgers, etc.). Future expansions may include more granular data.

---

## 3. Key Features

1. **Swiping for Cravings**  
   - **Craving/Current Tab**: Users indicate "like," "dislike," or "neutral" by swiping. These are short‐term preferences that inform real‐time cravings.  
   - **All/Explore Tab**: Users can see a broader set of food videos and discover new ideas.

2. **Daily Cravings Meter**  
   - Each user has a visible meter around their profile icon, signifying how many swipes they have completed for the day.  
   - Once the meter is full, the system considers the user's "daily cravings" to be updated. A partially filled meter still contributes partial data.

3. **Group Consensus Mechanic**  
   - Groups can view each member's daily cravings status.  
   - The top shared craving is displayed prominently.  
   - One veto is allowed per group member. Upon veto, the system displays the next top item.  
   - If no more items are available (all vetoed), the app encourages more swiping or allows a veto undo.

4. **Restaurant & Recipe Suggestions**  
   - **Restaurants**: For a given dish the group has in common, the app looks up local restaurants.  
   - **Recipes**: If everyone in the group is craving a certain dish, the system displays relevant recipes (along with ingredients, prep steps, etc.).

5. **Personal Analytics**  
   - Track how cravings and preferences evolve over time.  
   - Produce simple charts or data summaries for personal or group use.

6. **Social & Content Creation**  
   - **Food Posting**: Users can take a picture/video of food and have it appear on their profile.
     - Photos/videos are tagged automatically or manually with the relevant food item.
     - Posted content also appears in the feed for friends or followers to view.
   - **Friends List**: Users can maintain a list of friends, view their profiles, and add new friends.

---

## 4. MVP Scope

1. **User Authentication**  
   - Utilize Firebase Authentication (social logins or email).  
   - Store basic profile information and daily craving stats.

2. **Basic Video Feed**  
   - Flutter frontend displays short food videos in a scrollable feed.  
   - Python backend serves video metadata (title, category, URLs).  
   - Firebase or a simple storage solution for user actions (likes, bookmarks, etc.).

3. **Daily Craving Meter**  
   - Increment meter for each swipe.  
   - Show partially filled meter until the user has completed enough swipes.

4. **Group Functionality**  
   - Ability to create or join a group.  
   - One shared group "Cravings" page that reflects aggregated short‐term cravings.

5. **Restaurant & Recipe Suggestions (Basic Version)**  
   - Hardcoded or simplified recommendation flow for the first iteration.  
   - Display top suggestion based on group's top dish.

---

## 5. Technical Approach

### 5.1 Frontend (Flutter)
1. **Cross‐Platform UI**  
   - Single codebase for iOS and Android.  
   - Tabs for "Craving/Current" and "All/Explore."  
   - Home screen that shows daily cravings and group status.

2. **Core Packages**  
   - Firebase SDK for authentication and real‐time updates.  
   - Video player plugins for displaying short‐form content (e.g., for TikTok‐like scrolling).

3. **Navigation & State Management**  
   - Possible use of `Provider`, `Riverpod`, or `Bloc` for managing swiping actions and group states.

### 5.2 Backend (Python)
1. **Framework**  
   - FastAPI or Flask for handling RESTful API requests.  
   - Endpoints for:  
     - CRUD operations on user objects and preferences.  
     - Group creation and retrieval.  
     - Aggregation logic (group's top cravings).  

2. **Data Storage**  
   - Firebase Realtime Database or Firestore for swipes, group data, and user profiles.  
   - Cloud Storage (e.g., Firebase Storage) or a separate object store for videos (if needed).

3. **Recommendation Service (Future Enhancement)**  
   - For MVP, keep it simple: filter by top cravings, show relevant items.  
   - Expand to more advanced ML or collaborative filtering in future phases.

### 5.3 Firebase Integration
1. **Authentication**  
   - Users authenticate via Firebase. Tokens are passed to the Python backend to verify requests.  

2. **Firestore or Realtime Database**  
   - Store swiping actions, daily craving meters, group membership, and current top item.  

3. **Cloud Functions (Optional)**  
   - Could handle event‐driven tasks such as updating group's top item when a user's meter completes.

---

## 6. Infrastructure Reference

Our approach partly mirrors best practices for short‐form video apps (see [@stack_infrastructure.md] for reference). Key points to note:

1. **Scalability & Serverless**  
   - Firebase scales seamlessly for MVP usage.  
   - If usage spikes, we can containerize the Python backend and deploy on a managed Kubernetes service.

2. **Media Storage**  
   - Videos can be stored in Firebase Storage or a separate CDN.  
   - For initial prototypes, smaller video files or GIF‐style content may suffice until usage grows.

3. **Monitoring & Logging**  
   - Rely on lightweight analytics from Firebase.  
   - Expand to more mature stacks (e.g., ELK, Prometheus) if needed.

---

## 7. Timeline

| Milestone                   | Target          | Description                                                    |
|----------------------------|-----------------|----------------------------------------------------------------|
| **Requirements & Design**  | 1–2 weeks       | Finalize user stories, flows, and data models.                |
| **MVP Backend**            | 2–3 weeks       | Basic Python APIs + Firebase integration.                     |
| **MVP Frontend**           | 3–4 weeks       | Flutter UI with swiping, daily meter, group screens.          |
| **Testing & Refinements**  | 1–2 weeks       | QA, bug fixes, minor adjustments.                             |
| **Initial Launch**         | ~ 8–10 weeks    | Deploy MVP to limited user base for feedback.                 |

---

## 8. Future Considerations

1. **Advanced ML Recommendations**: Integrate a streaming data platform and advanced recommendation models.  
2. **Rich Social Features**: Comments, in‐app messaging, duets, etc.  
3. **Monetization**: Potential for ads or brand partnerships once user base is established.  
4. **Global Expansion**: L10N and multi‐region support.

---

## 9. Open Questions

1. **Further Customizations for Groups**: How do we handle larger groups or complex dietary restrictions?  
2. **Specialty Camera Effects**: Do we need AR filters or editing features beyond standard uploading?  
3. **Offline Capabilities**: Are we targeting users in low‐connectivity regions?

---

**End of Document** 