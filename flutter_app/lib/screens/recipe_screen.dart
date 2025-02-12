import 'package:flutter/material.dart';
import '../models/feed_item.dart';

class RecipeScreen extends StatelessWidget {
  // The post object holds all the data, including recipe details.
  final FeedItem post;

  // The RecipeScreen requires a post containing recipe data.
  const RecipeScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Extract the recipe steps and ingredients from the post.
    // We assume that these fields hold a list of maps.
    final List<dynamic> recipeSteps = post.recipe ?? [];
    final List<dynamic> ingredients = post.ingredients ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Details"),
      ),
      body: GestureDetector(
        onPanEnd: (details) {
          // Swipe left to return to feed
          if (details.velocity.pixelsPerSecond.dx < 0) {
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Display a list of ingredients if available.
              if (ingredients.isNotEmpty) ...[
                Text(
                  "Ingredients",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...ingredients.map((ingredient) {
                  // Each ingredient is expected to be a map with keys "ingredient" and "quantity".
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "- ${ingredient['ingredient']}: ${ingredient['quantity']}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              // Display the step-by-step recipe if available.
              if (recipeSteps.isNotEmpty) ...[
                Text(
                  "Recipe Steps",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...recipeSteps.map((step) {
                  // Each step should have a numeric 'step' and a string 'instruction'.
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      "Step ${step['step']}: ${step['instruction']}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
