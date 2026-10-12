/**
 * Estonia Driving Theory - Centralized Application Configuration
 * All key URLs, support emails, and metadata are maintained here for easy updates.
 */
const APP_CONFIG = {
  appName: "Estonia Driving Theory",
  appCategory: "Category B Driving Theory Preparation",
  
  // App Store URL:
  // Replace '#' with your live App Store URL once your app is approved in App Store Connect.
  // Example: "https://apps.apple.com/app/id6470000000"
  appStoreUrl: "#",
  isAppStoreLive: false,

  // Support Contact Email:
  // Centralized placeholder configured as specified.
  supportEmail: "raxitsingh2002@gmail.com",

  // Supported Languages
  defaultLanguage: "en",
  supportedLanguages: ["en", "et", "ru"],

  // Legal & Meta
  lastUpdated: "October 2026",
  copyrightYear: 2026,
  developer: "Estonia Driving Theory",
  
  // Pricing display
  pricing: {
    monthly: "€4.99",
    lifetime: "€7.99"
  }
};

// Export for module or browser window
if (typeof window !== "undefined") {
  window.APP_CONFIG = APP_CONFIG;
}
if (typeof module !== "undefined" && module.exports) {
  module.exports = APP_CONFIG;
}
