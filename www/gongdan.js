(function () {
  "use strict";

  var storageKey = "repairdesk-privacy-language";

  function detectLanguage() {
    var languages = Array.isArray(navigator.languages) && navigator.languages.length
      ? navigator.languages
      : [navigator.language || ""];
    var savedLanguage = null;

    try {
      savedLanguage = localStorage.getItem(storageKey);
    } catch (error) {
      savedLanguage = null;
    }

    if (savedLanguage === "zh" || savedLanguage === "en") {
      return savedLanguage;
    }

    return languages.some(function (item) {
      return /^zh(?:-|$)/i.test(item);
    }) ? "zh" : "en";
  }

  function setLanguage(language, persist) {
    var normalizedLanguage = language === "en" ? "en" : "zh";
    var root = document.documentElement;
    var selectedInput = document.getElementById("language-" + normalizedLanguage);

    root.dataset.language = normalizedLanguage;
    root.lang = normalizedLanguage === "en" ? "en" : "zh-CN";
    document.title = normalizedLanguage === "en"
      ? "Repair Work Orders | Privacy Policy"
      : "维修工单助手｜隐私权政策";

    if (selectedInput) {
      selectedInput.checked = true;
    }

    if (persist) {
      try {
        localStorage.setItem(storageKey, normalizedLanguage);
      } catch (error) {
        // Language switching still works when storage is unavailable.
      }
    }
  }

  function init() {
    var languageOptions = document.querySelectorAll("[data-language-option]");

    languageOptions.forEach(function (option) {
      option.addEventListener("click", function () {
        setLanguage(option.dataset.languageOption, true);
      });
    });

    setLanguage(detectLanguage(), false);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();
