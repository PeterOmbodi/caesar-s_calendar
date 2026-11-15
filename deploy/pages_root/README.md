# Root of peterombodi.github.io

Copy these files to the root of the `peterombodi.github.io` repository so that room links
(`https://peterombodi.github.io/caesar-s_calendar/?race=CODE`) open the installed app.

- `.nojekyll` — GitHub Pages serves `.well-known` (Jekyll would skip it).
- `.well-known/apple-app-site-association` — iOS Universal Links for the App ID `4YB4K9WAB4.com.peter.ombodi.caesarPuzzle`.
- `.well-known/assetlinks.json` — Android App Links: Play app signing key and the debug key.

Check after publishing:
- https://peterombodi.github.io/.well-known/apple-app-site-association
- https://peterombodi.github.io/.well-known/assetlinks.json
- https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://peterombodi.github.io&relation=delegate_permission/common.handle_all_urls
