This is a video scrolling app similar to TikTok.

Niche: Food only. We aim to build a dataset of what users are currently craving, and then use that to:

- Recommend recipes, restaurants
- Build consensus on what to eat in group settings

User stories (6):

- I want to be able to take a picture / video of food and have it be visible on my profile
1) Take a picture / video of food
2) See it on my profile
3) Tagged with the food item
4) See it on the feeds

- I want to scroll through videos of food and have it learn my current cravings
1) Scroll through videos of food
2) Like/Heart for current cravings
3) Bookmark icon for something new I want to try later
4) The app learns my preferences for the day
5) My preferences decay over time / can be manually reset

- I want data on my preferences, and how they change over time
1) See my current preferences
2) See a graph of my preferences over time
3) See a graph of the group's preferences over time
4) See a graph of the most popular trending food items over time

- I want a progress bar of my swipes
1) Daily reset of progress bar
2) Every time I swipe, the progress bar goes up
3) The progress is displayed in a circular progress bar around my profile picture
4) Once the progress bar is full, I can no longer swipe
5) Once the progress bar is full, my cravings data is saved for the day (visible from trends)

- I want to have a friend's list
1) Ability to add friends by username
2) Ability to send friend request
3) Ability to accept friend request
4) Ability to see list of friends

- I want to have friend groups
1) Ability to create a group
2) Ability to add friends to a group
3) Ability to remove friends from a group
4) Ability to see a list of friends in a group
5) Ability to see a list of groups I am in

- I want to build consensus on what to eat in group settings
1) Create a group
2) See everyone's profiles, what they are currently craving (number of hearts near their profile), what the group craves (number of hearts)
3) If a group member does not have updated cravings, the app will prompt them to update their cravings by swiping
3) Large image of the top food item the group is craving displayed in the center of the screen
4) Initiate timed voting game with notifications
*) (Everyone gets 1 veto, which will display the next food)

- I want to scroll through my feed and see a variety of food items
1) See a list of food items that match my preferences
2) See a list of food items that match the group's preferences
3) See items I have bookmarked
4) See items related to foods I have liked
5) See new pictures / videos of food items each time (e.g. pizza is popular, but we don't want to show the same pizza over and over)

- I want restaurant recommendations
1) See a list of restaurants near me that have the food I am craving

- I want recipe recommendations
1) See a list of recipes that match my preferences
2) See a list of recipes that match the group's preferences
3) See a list of ingredients I need to buy to make the recipe

- I want a feed algorithm for X percent new, and X percent things I like
1) Feed algorithm based on my preferences, and preferences of people I follow
2) Feed algorithm based on the group's preferences
3) Something "new" feed, which shows new foods

- I want ratings and reviews for restaurants
1) See a list of friend ratings for a restaurant
2) X approve, X disapprove (4+ star vs 3- star?)

- I want to see a custom pentagon stat page for my 5 favorite tags
1) See pengaton stats on each profile
2) Modify top 5 tags to display
3) Compare pentagon stats with friends

AI Stories:
- I want AI to automatically analyze my videos
1) Take frames, send to AI to analyze
2) AI generates tags, description, and recipe

- I want AI to automatically modify my feed to show less of things that may fall under my food restrictions

- I want AI to recommend me restaurants based on my preferences

- I want to be able to swipe right and left on videos
0) Record in Interactactions document
1) Swipe right: Generate restaurant recommendations based on AI description / tags / user location
2) Swipe left: Generate recipe recommendations based on AI description / tags

- I want AI to automatically do content moderation
1) Report posts that are not food
2) Report posts that are not safe for work

Stretch stories:

- I want to be able to add music to my videos
- I want AI to automatically tag foods in my videos
- I want the videos to load faster (cache, reduce resolution, chunk videos, etc) -> done
- I want a feed algorithm for X percent new, and X percent things I like
