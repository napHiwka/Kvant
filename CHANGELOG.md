# Changelog

## 0.9.4
- 9e27da2 feat: make grip more comfortable (ux) feal: update types refactor: code cleanup related to icons & secure mode
- c73fec1 feat: add posibility to add elements in Status frame via :Content
feat: add secure option to CreateWindow (for now only disables all icons)
feat: add icon to regular pill refactor: icons related logic & make them runtime changeable
fix: text jigling on window toggle animation api: rename AutoTabIcons to AutoIcons

## 0.9.3
- e33bb4d feat:  add full roblox studio support feat: customizeble pill variant (round or pill) fix: firing mouse on dragging status frame fix: textarea typing access fix: textarea locking functionality style: small code style without changing functionality fix: user can't see tooltip if element locked
- 6cd47ac feat: update types
- d229b86 feat: better window positioning
- 03623d9 feat: grip pill feat: window clamping (need adjustments) feat: save win & pill position
- 0cd3cef feat: remove register at _G and secure others env's behind flag
- 0af8d82 feat: add test-cases
- cb94c9c refactor: closer to perfect, but still far from it; sob
- 0a29e95 refactor: split code in sections feat: search with autocomplete, jumping to elements feat: lock/unlock functionality feat: small tooltips style: extract constants style: better hover effect on elements refactor: use json for persistance because it much faster perf: improve performance via element pool in dropdowns fix: typo in solar theme name fix: separate state of multiple windows style fix: roblox gui elements formatting inconsistency style: center notifiications style: center dropdown select box style: better input ux fix: color saves correctly fix: small bug fixes all around code
- 1660c1a major: center div
- ae89324 style: remove stylua to keep consistent manual formatting
- 4b3d90b feat: add types
- 658560d style: change default font to roboto
- de2d19f style: themes formatting feat: add scopes for declarative code style feat: add new light theme feat: add handle methods for elements (getters, setters, etc...)
- 129f7dc feat: runtime theme changing feat: custom themes validation feat: auto inverse icon color depen on theme (dark or light) palett feat: runtime font changing feat: custom fonts feat: better unlock cursor handling style: better dropdown (similar to input) fix: toggle off icons not working fix: text size in inputs & dropdowns
- f32d167 refactor: condense code (someone will hate it) style: pill adopts better for text style: sections have better text icons style: big Input fields style: bigger text sizes feat: custom window sizes feat: new themes fix: muted text on hover
- f6825b0 feat: config persistance feat: settings icon & panel feat: unlock cursor on menu open feat: better colorpicker feat: collapsible sections fix: debounce for prev value in slider style: better ux
- 8fbce14 feat: disable notifications in settings - style: improve scrollbars visual - fix: collapse not using right win sizer
- d1fb6c4 refactor: reduce code duplication
- bda56a3 feat: improve UI scaling options feat: change parameters order for faster code experience feat: add Input API feat: add Notify API feat: improve animations feat: add new options to Settings feat: add step option to Slider feat: new default window sizes fix: incorrectly calculated frame height in dropdown fix: destroy every created signal by lib on close fix: add layout order to fix the random order of elements
- 00d5d92 initial kvant commit
- 1d8045e init commit
