const {
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold,
} = require("@google/generative-ai");
const { GoogleAIFileManager } = require("@google/generative-ai/server");

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);
const fileManager = new GoogleAIFileManager(apiKey);

/**
 * Uploads the given file to Gemini.
 *
 * See https://ai.google.dev/gemini-api/docs/prompting_with_media
 */
async function uploadToGemini(path, mimeType) {
  const uploadResult = await fileManager.uploadFile(path, {
    mimeType,
    displayName: path,
  });
  const file = uploadResult.file;
  console.log(`Uploaded file ${file.displayName} as: ${file.name}`);
  return file;
}

/**
 * Waits for the given files to be active.
 *
 * Some files uploaded to the Gemini API need to be processed before they can
 * be used as prompt inputs. The status can be seen by querying the file's
 * "state" field.
 *
 * This implementation uses a simple blocking polling loop. Production code
 * should probably employ a more sophisticated approach.
 */
async function waitForFilesActive(files) {
  console.log("Waiting for file processing...");
  for (const name of files.map((file) => file.name)) {
    let file = await fileManager.getFile(name);
    while (file.state === "PROCESSING") {
      process.stdout.write(".")
      await new Promise((resolve) => setTimeout(resolve, 10_000));
      file = await fileManager.getFile(name)
    }
    if (file.state !== "ACTIVE") {
      throw Error(`File ${file.name} failed to process`);
    }
  }
  console.log("...all files ready\n");
}

const model = genAI.getGenerativeModel({
  model: "gemini-2.0-flash",
});

const generationConfig = {
  temperature: 1,
  topP: 0.95,
  topK: 40,
  maxOutputTokens: 8192,
  responseMimeType: "text/plain",
};

async function run() {
  // TODO Make these files available on the local file system
  // You may need to update the file paths
  const files = [
    await uploadToGemini("1111421-hd_1920_1080_30fps.mp4", "video/mp4"),
  ];

  // Some files have a processing delay. Wait for them to be ready.
  await waitForFilesActive(files);

  const chatSession = model.startChat({
    generationConfig,
    history: [
      {
        role: "user",
        parts: [
          {
            fileData: {
              mimeType: files[0].mimeType,
              fileUri: files[0].uri,
            },
          },
        ],
      },
      {
        role: "user",
        parts: [
          {text: "\n        Video analysis, returning primary food tags (e.g. pizza, and or italian,\n        but not dough or tomato sauce), detailed description of the food in the\n        video, quantified ingredients, detailed step by step recipe with\n        quantified ingredient usage, and content moderation\n        (if topic is_food_related, or topic is_nsfw, also add a \"reason\"\n        field that states why content moderation failed).\n\n        Format your response as JSON with these fields:\n        {\n          \"video_id\": \"unique_video_identifier\",\n          \"topic\": \"food_related\",\n          \"primary_food_tags\": [\"pizza\", \"italian\"],\n          \"detailed_food_description\": \"A pepperoni pizza with a thick crust...\",\n          \"quantified_ingredients\": [\n            {\"ingredient\": \"pizza dough\", \"quantity\": \"500g\"}\n          ],\n          \"detailed_step_by_step_recipe\": [\n            {\"step\": 1, \"instruction\": \"Preheat oven to 220°C (425°F).\"}\n          ],\n          \"content_moderation\": {\n            \"is_food_related\": true,\n            \"is_nsfw\": false,\n            \"reason\": null\n          }"},
        ],
      },
      {
        role: "model",
        parts: [
          {text: "```json\n{\n  \"video_id\": \"unique_video_identifier\",\n  \"topic\": \"food_related\",\n  \"primary_food_tags\": [\n    \"pork belly\",\n    \"kimchi\",\n    \"Korean BBQ\"\n  ],\n  \"detailed_food_description\": \"Korean BBQ being cooked on a grill with pork belly and kimchi.\",\n  \"quantified_ingredients\": [\n    {\n      \"ingredient\": \"pork belly\",\n      \"quantity\": \"varied\"\n    },\n    {\n      \"ingredient\": \"kimchi\",\n      \"quantity\": \"varied\"\n    }\n  ],\n  \"detailed_step_by_step_recipe\": [\n    {\n      \"step\": 1,\n      \"instruction\": \"Place pork belly on the grill.\"\n    },\n    {\n      \"step\": 2,\n      \"instruction\": \"Cook pork belly until browned on one side.\"\n    },\n    {\n      \"step\": 3,\n      \"instruction\": \"Flip pork belly and continue cooking until done.\"\n    },\n    {\n      \"step\": 4,\n      \"instruction\": \"Add kimchi to the grill to cook.\"\n    }\n  ],\n  \"content_moderation\": {\n    \"is_food_related\": true,\n    \"is_nsfw\": false,\n    \"reason\": null\n  }\n}\n```"},
        ],
      },
    ],
  });

  const result = await chatSession.sendMessage("INSERT_INPUT_HERE");
  console.log(result.response.text());
}

run();