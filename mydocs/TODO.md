Fixes:
1) Cloud function: Remove trigger on blob data (matches search file structure rn)
2) Fix thumbnail generation bug too wide: https://chatgpt.com/c/67a3781e-aa9c-8004-89b4-90c420342044 (done)
3) Fix video screen slightly misaligned on the right side (video blur?)
4) Newly uploaded videos don't load instantly -> Fixed by eventual feed algorithm (which won't load newly uploaded videos instantly)

Beautification
1) Welcome flow, showcasing features
2) Profile page (edit profile) (done)
3) UI changes

Optimizations
1) 
2) Optimize videos
  a) Video compression
  b) Video caching (+1 prefetch done)
  c) Lower resolution/ multiresolution
  d) Streaming / chunking (hls done)
3) Feed algorithm

Features
1) Explore page
2) Daily resets of cravings / manual test reset button
3) fix the like/heart button in the feed to implement tracking in users subcollection
4) Add an option to selectively "like" certain tags if a video has multiple tags. (Start with all tags selected, tap on tag to deselect).
5) Left / Right swipes: Restaurant / Recipe

Security
1) Appcheck
W/StorageUtil(28224): Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
2) Serious auth (phone number verification)
3) Upload file size limits

AI
- I want AI to automatically analyze my videos
1) Take frames, send to AI to analyze
2) AI generates tags, description, and recipe

Thursday 2/6
1) Video optimizations: Client-side prefetching (done)
2) Video optimizations: HLS streaming (done) -> seems decently fast, maybe don't strictly need compression rn. Could increase cache size.
3) Misc: profile video tab, feed profile icon, profile edit profile pics (done)

Friday 2/7
1) Feature:delete videos (done)
2) Fix liking other vids, simplify bottom nav UI (done)
3) Trends and preferences snapshots (done)
4) Upload confirmation (done)

Saturday 2/8
1) Code audit / misc
"It's time for a code audit! Go through the codebase (the code itself, ignore the documentation), into every nook and cranny, and provide a report on things to improve. Note down any unnecessary duplicated code, potential for refactoring, or just suggestions you think would help the codebase me more maintainable."

Monday 2/10 (AI week)
1) Daily Swipe Froupin' time group voting feature
2) Notifications with voting feature
3) Fix thumbnail generation bug too wide: https://chatgpt.com/c/67a3781e-aa9c-8004-89b4-90c420342044 (done)
4) Upgrade to cloud functions v2
5) Update cloud function to be parallelized
6) Update cloud function to use more memory for video processing (GiB not GB) (done)

Tuesday 2/11 (AI start)
1) AI: Gemini 2.0 video / image frame analysis
2) Auto-Recipe screen, auto-tags, auto-description (done)

Wednesday 2/12
1) Radar chart preferences -> change to hexagon instead of pentagon (todo)
2) Content moderation (done)
3) Restaurant Recommendations?

Thursday 2/13
1) Restaurant recomendations (location based API and google places)
2) Caching, sorting
3) UI fixes

Friday 2/14
1) Feed algorithm

Beyond
1) Feed algorithm
2) Explore page / AI features
3) iOs build? Android production build?
4) Firebase beta distributions?
5) Fix Profile video bugs: (thumbnail stretched, videos should be same as feed ui)