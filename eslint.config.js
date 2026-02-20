import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["app/javascript/**/*.{ts,js}"],
    rules: {},
  },
  {
    ignores: ["node_modules/", "app/assets/builds/", "vendor/"],
  }
);
