// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `load-ids` option is passed. Each load ID maps to one
  //   or more wasm files as specified in the emitted JSON file. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It also takes a callback that should be invoked with the
  //   loaded module in a format supported by `WebAssembly.compile` or
  //   `WebAssembly.compileStreaming` and the result of using the JS 'import'
  //   API on the js file path. It should return a Promise that resolves when
  //   all the modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports,
      {loadDeferredModules, loadDynamicModule, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _1: (decoder, codeUnits) => decoder.decode(codeUnits),
      _2: () => new TextDecoder("utf-8", {fatal: true}),
      _3: () => new TextDecoder("utf-8", {fatal: false}),
      _4: (s) => +s,
      _5: x0 => new Uint8Array(x0),
      _6: (x0,x1,x2) => x0.set(x1,x2),
      _7: (x0,x1) => x0.transferFromImageBitmap(x1),
      _8: x0 => x0.arrayBuffer(),
      _9: (x0,x1,x2) => x0.slice(x1,x2),
      _10: (x0,x1) => x0.decode(x1),
      _11: (x0,x1) => x0.segment(x1),
      _12: () => new TextDecoder(),
      _14: x0 => x0.buffer,
      _15: x0 => x0.wasmMemory,
      _16: () => globalThis.window._flutter_skwasmInstance,
      _17: x0 => x0.rasterStartMilliseconds,
      _18: x0 => x0.rasterEndMilliseconds,
      _19: x0 => x0.imageBitmaps,
      _135: (x0,x1) => x0.appendChild(x1),
      _166: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _167: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _168: (x0,x1) => new OffscreenCanvas(x0,x1),
      _169: x0 => x0.remove(),
      _170: (x0,x1) => x0.append(x1),
      _172: x0 => x0.unlock(),
      _173: x0 => x0.getReader(),
      _174: (x0,x1) => x0.item(x1),
      _175: x0 => x0.next(),
      _176: x0 => x0.now(),
      _177: (x0,x1) => x0.revokeObjectURL(x1),
      _178: x0 => x0.close(),
      _179: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _180: x0 => new window.ImageDecoder(x0),
      _181: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      _182: (x0,x1) => x0.decode(x1),
      _183: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._183(f,arguments.length,x0) }),
      _184: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _186: (x0,x1) => x0.getModifierState(x1),
      _187: x0 => x0.preventDefault(),
      _188: x0 => x0.stopPropagation(),
      _189: (x0,x1) => x0.removeProperty(x1),
      _190: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._190(f,arguments.length,x0) }),
      _191: x0 => new window.FinalizationRegistry(x0),
      _192: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _194: (x0,x1) => x0.unregister(x1),
      _195: (x0,x1) => x0.prepend(x1),
      _196: x0 => new Intl.Locale(x0),
      _197: (x0,x1) => x0.observe(x1),
      _198: x0 => x0.disconnect(),
      _199: (x0,x1) => x0.getAttribute(x1),
      _200: (x0,x1) => x0.contains(x1),
      _201: (x0,x1) => x0.querySelector(x1),
      _202: (x0,x1) => x0.matchMedia(x1),
      _203: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._203(f,arguments.length,x0) }),
      _204: (x0,x1,x2) => x0.call(x1,x2),
      _205: x0 => x0.blur(),
      _206: x0 => x0.hasFocus(),
      _207: (x0,x1) => x0.removeAttribute(x1),
      _208: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _209: (x0,x1) => x0.hasAttribute(x1),
      _210: (x0,x1) => x0.getModifierState(x1),
      _211: (x0,x1) => x0.createTextNode(x1),
      _212: x0 => x0.getBoundingClientRect(),
      _213: (x0,x1) => x0.replaceWith(x1),
      _214: (x0,x1) => x0.contains(x1),
      _215: (x0,x1) => x0.closest(x1),
      _216: () => new Array(),
      _653: x0 => new Uint8Array(x0),
      _656: () => globalThis.window.flutterConfiguration,
      _658: x0 => x0.assetBase,
      _663: x0 => x0.canvasKitMaximumSurfaces,
      _664: x0 => x0.debugShowSemanticsNodes,
      _665: x0 => x0.hostElement,
      _666: x0 => x0.multiViewEnabled,
      _667: x0 => x0.nonce,
      _669: x0 => x0.fontFallbackBaseUrl,
      _679: x0 => x0.console,
      _680: x0 => x0.devicePixelRatio,
      _681: x0 => x0.document,
      _682: x0 => x0.history,
      _683: x0 => x0.innerHeight,
      _684: x0 => x0.innerWidth,
      _685: x0 => x0.location,
      _686: x0 => x0.navigator,
      _687: x0 => x0.visualViewport,
      _688: x0 => x0.performance,
      _689: x0 => x0.parent,
      _691: x0 => x0.URL,
      _693: (x0,x1) => x0.getComputedStyle(x1),
      _694: x0 => x0.screen,
      _695: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._695(f,arguments.length,x0) }),
      _696: (x0,x1) => x0.requestAnimationFrame(x1),
      _700: (x0,x1) => x0.warn(x1),
      _702: (x0,x1) => x0.debug(x1),
      _703: x0 => globalThis.parseFloat(x0),
      _704: () => globalThis.window,
      _705: () => globalThis.Intl,
      _706: () => globalThis.Symbol,
      _707: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _709: x0 => x0.clipboard,
      _710: x0 => x0.maxTouchPoints,
      _711: x0 => x0.vendor,
      _712: x0 => x0.language,
      _713: x0 => x0.platform,
      _714: x0 => x0.userAgent,
      _715: (x0,x1) => x0.vibrate(x1),
      _716: x0 => x0.languages,
      _717: x0 => x0.documentElement,
      _718: (x0,x1) => x0.querySelector(x1),
      _719: (x0,x1) => x0.querySelectorAll(x1),
      _721: (x0,x1) => x0.createElement(x1),
      _724: (x0,x1) => x0.createEvent(x1),
      _725: x0 => x0.activeElement,
      _728: x0 => x0.head,
      _729: x0 => x0.body,
      _731: (x0,x1) => { x0.title = x1 },
      _734: x0 => x0.visibilityState,
      _735: () => globalThis.document,
      _736: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._736(f,arguments.length,x0) }),
      _737: (x0,x1) => x0.dispatchEvent(x1),
      _745: x0 => x0.target,
      _747: x0 => x0.timeStamp,
      _748: x0 => x0.type,
      _750: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _757: x0 => x0.firstChild,
      _761: x0 => x0.parentElement,
      _763: (x0,x1) => { x0.textContent = x1 },
      _764: x0 => x0.parentNode,
      _765: x0 => x0.nextSibling,
      _766: (x0,x1) => x0.removeChild(x1),
      _767: x0 => x0.isConnected,
      _775: x0 => x0.clientHeight,
      _776: x0 => x0.clientWidth,
      _777: x0 => x0.offsetHeight,
      _778: x0 => x0.offsetWidth,
      _779: x0 => x0.id,
      _780: (x0,x1) => { x0.id = x1 },
      _783: (x0,x1) => { x0.spellcheck = x1 },
      _784: x0 => x0.tagName,
      _785: x0 => x0.style,
      _787: (x0,x1) => x0.querySelectorAll(x1),
      _788: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _789: x0 => x0.tabIndex,
      _790: (x0,x1) => { x0.tabIndex = x1 },
      _791: (x0,x1) => x0.focus(x1),
      _792: x0 => x0.scrollTop,
      _793: (x0,x1) => { x0.scrollTop = x1 },
      _794: (x0,x1) => { x0.scrollLeft = x1 },
      _795: x0 => x0.scrollLeft,
      _796: x0 => x0.classList,
      _797: (x0,x1) => x0.scrollIntoView(x1),
      _800: (x0,x1) => { x0.className = x1 },
      _802: (x0,x1) => x0.getElementsByClassName(x1),
      _803: x0 => x0.click(),
      _804: (x0,x1) => x0.attachShadow(x1),
      _807: x0 => x0.computedStyleMap(),
      _808: (x0,x1) => x0.get(x1),
      _814: (x0,x1) => x0.getPropertyValue(x1),
      _815: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _816: x0 => x0.offsetLeft,
      _817: x0 => x0.offsetTop,
      _818: x0 => x0.offsetParent,
      _820: (x0,x1) => { x0.name = x1 },
      _821: x0 => x0.content,
      _822: (x0,x1) => { x0.content = x1 },
      _826: (x0,x1) => { x0.src = x1 },
      _827: x0 => x0.naturalWidth,
      _828: x0 => x0.naturalHeight,
      _832: (x0,x1) => { x0.crossOrigin = x1 },
      _834: (x0,x1) => { x0.decoding = x1 },
      _835: x0 => x0.decode(),
      _840: (x0,x1) => { x0.nonce = x1 },
      _845: (x0,x1) => { x0.width = x1 },
      _847: (x0,x1) => { x0.height = x1 },
      _850: (x0,x1) => x0.getContext(x1),
      _918: x0 => x0.width,
      _919: x0 => x0.height,
      _921: (x0,x1) => x0.fetch(x1),
      _922: x0 => x0.status,
      _924: x0 => x0.body,
      _925: x0 => x0.arrayBuffer(),
      _928: x0 => x0.read(),
      _929: x0 => x0.value,
      _930: x0 => x0.done,
      _937: x0 => x0.name,
      _938: x0 => x0.x,
      _939: x0 => x0.y,
      _942: x0 => x0.top,
      _943: x0 => x0.right,
      _944: x0 => x0.bottom,
      _945: x0 => x0.left,
      _955: x0 => x0.height,
      _956: x0 => x0.width,
      _957: x0 => x0.scale,
      _958: (x0,x1) => { x0.value = x1 },
      _961: (x0,x1) => { x0.placeholder = x1 },
      _963: (x0,x1) => { x0.name = x1 },
      _964: x0 => x0.selectionDirection,
      _965: x0 => x0.selectionStart,
      _966: x0 => x0.selectionEnd,
      _969: x0 => x0.value,
      _971: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _972: x0 => x0.readText(),
      _973: (x0,x1) => x0.writeText(x1),
      _975: x0 => x0.altKey,
      _976: x0 => x0.code,
      _977: x0 => x0.ctrlKey,
      _978: x0 => x0.key,
      _979: x0 => x0.keyCode,
      _980: x0 => x0.location,
      _981: x0 => x0.metaKey,
      _982: x0 => x0.repeat,
      _983: x0 => x0.shiftKey,
      _984: x0 => x0.isComposing,
      _986: x0 => x0.state,
      _987: (x0,x1) => x0.go(x1),
      _989: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _990: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _991: x0 => x0.pathname,
      _992: x0 => x0.search,
      _993: x0 => x0.hash,
      _997: x0 => x0.state,
      _1000: (x0,x1) => x0.createObjectURL(x1),
      _1002: x0 => new Blob(x0),
      _1012: x0 => x0.matches,
      _1016: x0 => x0.matches,
      _1020: x0 => x0.relatedTarget,
      _1022: x0 => x0.clientX,
      _1023: x0 => x0.clientY,
      _1024: x0 => x0.offsetX,
      _1025: x0 => x0.offsetY,
      _1028: x0 => x0.button,
      _1029: x0 => x0.buttons,
      _1030: x0 => x0.ctrlKey,
      _1034: x0 => x0.pointerId,
      _1035: x0 => x0.pointerType,
      _1036: x0 => x0.pressure,
      _1037: x0 => x0.tiltX,
      _1038: x0 => x0.tiltY,
      _1039: x0 => x0.getCoalescedEvents(),
      _1042: x0 => x0.deltaX,
      _1043: x0 => x0.deltaY,
      _1044: x0 => x0.wheelDeltaX,
      _1045: x0 => x0.wheelDeltaY,
      _1046: x0 => x0.deltaMode,
      _1053: x0 => x0.changedTouches,
      _1056: x0 => x0.clientX,
      _1057: x0 => x0.clientY,
      _1060: x0 => x0.data,
      _1063: (x0,x1) => { x0.disabled = x1 },
      _1065: (x0,x1) => { x0.type = x1 },
      _1066: (x0,x1) => { x0.max = x1 },
      _1067: (x0,x1) => { x0.min = x1 },
      _1068: x0 => x0.value,
      _1069: (x0,x1) => { x0.value = x1 },
      _1070: x0 => x0.disabled,
      _1071: (x0,x1) => { x0.disabled = x1 },
      _1073: (x0,x1) => { x0.placeholder = x1 },
      _1075: (x0,x1) => { x0.name = x1 },
      _1076: (x0,x1) => { x0.autocomplete = x1 },
      _1078: x0 => x0.selectionDirection,
      _1079: x0 => x0.selectionStart,
      _1081: x0 => x0.selectionEnd,
      _1084: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1085: (x0,x1) => x0.add(x1),
      _1087: (x0,x1) => { x0.noValidate = x1 },
      _1088: (x0,x1) => { x0.method = x1 },
      _1089: (x0,x1) => { x0.action = x1 },
      _1095: (x0,x1) => x0.getContext(x1),
      _1097: x0 => x0.convertToBlob(),
      _1114: x0 => x0.orientation,
      _1115: x0 => x0.width,
      _1116: x0 => x0.height,
      _1117: (x0,x1) => x0.lock(x1),
      _1136: x0 => new ResizeObserver(x0),
      _1139: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1139(f,arguments.length,x0,x1) }),
      _1147: x0 => x0.length,
      _1148: x0 => x0.iterator,
      _1149: x0 => x0.Segmenter,
      _1150: x0 => x0.v8BreakIterator,
      _1151: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1154: x0 => x0.language,
      _1155: x0 => x0.script,
      _1156: x0 => x0.region,
      _1174: x0 => x0.done,
      _1175: x0 => x0.value,
      _1176: x0 => x0.index,
      _1180: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1181: (x0,x1) => x0.adoptText(x1),
      _1182: x0 => x0.first(),
      _1183: x0 => x0.next(),
      _1184: x0 => x0.current(),
      _1186: () => globalThis.window.FinalizationRegistry,
      _1197: x0 => x0.hostElement,
      _1198: x0 => x0.viewConstraints,
      _1201: x0 => x0.maxHeight,
      _1202: x0 => x0.maxWidth,
      _1203: x0 => x0.minHeight,
      _1204: x0 => x0.minWidth,
      _1205: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1205(f,arguments.length,x0) }),
      _1206: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1206(f,arguments.length,x0) }),
      _1207: (x0,x1) => ({addView: x0,removeView: x1}),
      _1210: x0 => x0.loader,
      _1211: () => globalThis._flutter,
      _1212: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1213: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1213(f,arguments.length,x0) }),
      _1214: (module,f) => finalizeWrapper(f, function() { return module.exports._1214(f,arguments.length) }),
      _1215: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1218: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1218(f,arguments.length,x0) }),
      _1219: x0 => ({runApp: x0}),
      _1221: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1221(f,arguments.length,x0,x1) }),
      _1222: x0 => new Promise(x0),
      _1223: x0 => x0.length,
      _1224: () => globalThis.window.ImageDecoder,
      _1225: x0 => x0.tracks,
      _1227: x0 => x0.completed,
      _1229: x0 => x0.image,
      _1235: x0 => x0.displayWidth,
      _1236: x0 => x0.displayHeight,
      _1237: x0 => x0.duration,
      _1240: x0 => x0.ready,
      _1241: x0 => x0.selectedTrack,
      _1242: x0 => x0.repetitionCount,
      _1243: x0 => x0.frameCount,
      _1290: (x0,x1) => x0.createElement(x1),
      _1296: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1298: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1299: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1300: (x0,x1) => x0.createElement(x1),
      _1301: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1303: (x0,x1) => x0.getAttribute(x1),
      _1307: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1308: (x0,x1) => x0.canShare(x1),
      _1309: (x0,x1) => x0.share(x1),
      _1312: (x0,x1) => ({files: x0,text: x1}),
      _1314: x0 => ({files: x0}),
      _1316: x0 => ({text: x0}),
      _1317: x0 => x0.click(),
      _1318: x0 => x0.remove(),
      _1319: () => ({}),
      _1320: (x0,x1,x2) => new File(x0,x1,x2),
      _1352: x0 => x0.toArray(),
      _1353: x0 => x0.toUint8Array(),
      _1354: x0 => ({serverTimestamps: x0}),
      _1355: x0 => ({source: x0}),
      _1356: x0 => ({merge: x0}),
      _1358: x0 => new firebase_firestore.FieldPath(x0),
      _1359: (x0,x1) => new firebase_firestore.FieldPath(x0,x1),
      _1360: (x0,x1,x2) => new firebase_firestore.FieldPath(x0,x1,x2),
      _1361: (x0,x1,x2,x3) => new firebase_firestore.FieldPath(x0,x1,x2,x3),
      _1362: (x0,x1,x2,x3,x4) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4),
      _1363: (x0,x1,x2,x3,x4,x5) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5),
      _1364: (x0,x1,x2,x3,x4,x5,x6) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6),
      _1365: (x0,x1,x2,x3,x4,x5,x6,x7) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7),
      _1366: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      _1367: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1368: () => globalThis.firebase_firestore.documentId(),
      _1369: (x0,x1) => new firebase_firestore.Timestamp(x0,x1),
      _1370: (x0,x1) => new firebase_firestore.GeoPoint(x0,x1),
      _1371: x0 => globalThis.firebase_firestore.vector(x0),
      _1372: x0 => globalThis.firebase_firestore.Bytes.fromUint8Array(x0),
      _1373: x0 => globalThis.firebase_firestore.writeBatch(x0),
      _1374: (x0,x1) => globalThis.firebase_firestore.collection(x0,x1),
      _1375: (x0,x1) => globalThis.firebase_firestore.collectionGroup(x0,x1),
      _1376: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      _1379: x0 => x0.call(),
      _1381: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1381(f,arguments.length,x0) }),
      _1382: x0 => ({maxAttempts: x0}),
      _1383: (x0,x1,x2) => globalThis.firebase_firestore.runTransaction(x0,x1,x2),
      _1403: x0 => x0.commit(),
      _1404: (x0,x1) => x0.delete(x1),
      _1406: (x0,x1,x2) => x0.set(x1,x2),
      _1407: x0 => globalThis.firebase_firestore.deleteDoc(x0),
      _1408: x0 => globalThis.firebase_firestore.getDoc(x0),
      _1409: x0 => globalThis.firebase_firestore.getDocFromServer(x0),
      _1410: x0 => globalThis.firebase_firestore.getDocFromCache(x0),
      _1416: (x0,x1,x2) => globalThis.firebase_firestore.setDoc(x0,x1,x2),
      _1417: (x0,x1) => globalThis.firebase_firestore.setDoc(x0,x1),
      _1418: (x0,x1) => globalThis.firebase_firestore.query(x0,x1),
      _1419: x0 => globalThis.firebase_firestore.getDocs(x0),
      _1420: x0 => globalThis.firebase_firestore.getDocsFromServer(x0),
      _1421: x0 => globalThis.firebase_firestore.getDocsFromCache(x0),
      _1422: x0 => globalThis.firebase_firestore.limit(x0),
      _1423: x0 => globalThis.firebase_firestore.limitToLast(x0),
      _1426: (x0,x1) => globalThis.firebase_firestore.orderBy(x0,x1),
      _1428: (x0,x1,x2) => globalThis.firebase_firestore.where(x0,x1,x2),
      _1433: (x0,x1) => x0.data(x1),
      _1437: x0 => x0.docChanges(),
      _1441: (x0,x1) => x0.get(x1),
      _1443: (x0,x1,x2) => x0.set(x1,x2),
      _1444: () => globalThis.firebase_firestore.deleteField(),
      _1445: () => globalThis.firebase_firestore.serverTimestamp(),
      _1447: () => globalThis.firebase_firestore.count(),
      _1448: x0 => globalThis.firebase_firestore.sum(x0),
      _1449: x0 => globalThis.firebase_firestore.average(x0),
      _1450: (x0,x1) => globalThis.firebase_firestore.getAggregateFromServer(x0,x1),
      _1451: x0 => x0.data(),
      _1455: (x0,x1) => globalThis.firebase_firestore.getFirestore(x0,x1),
      _1457: x0 => globalThis.firebase_firestore.Timestamp.fromMillis(x0),
      _1458: (module,f) => finalizeWrapper(f, function() { return module.exports._1458(f,arguments.length) }),
      _1597: () => globalThis.firebase_firestore.or,
      _1598: () => globalThis.firebase_firestore.and,
      _1612: x0 => x0.path,
      _1615: () => globalThis.firebase_firestore.GeoPoint,
      _1616: x0 => x0.latitude,
      _1617: x0 => x0.longitude,
      _1619: () => globalThis.firebase_firestore.VectorValue,
      _1620: () => globalThis.firebase_firestore.Bytes,
      _1623: x0 => x0.type,
      _1625: x0 => x0.doc,
      _1627: x0 => x0.oldIndex,
      _1629: x0 => x0.newIndex,
      _1631: () => globalThis.firebase_firestore.DocumentReference,
      _1635: x0 => x0.path,
      _1644: x0 => x0.metadata,
      _1645: x0 => x0.ref,
      _1650: x0 => x0.docs,
      _1652: x0 => x0.metadata,
      _1657: () => globalThis.firebase_firestore.Timestamp,
      _1658: x0 => x0.seconds,
      _1659: x0 => x0.nanoseconds,
      _1695: x0 => x0.hasPendingWrites,
      _1697: x0 => x0.fromCache,
      _1704: x0 => x0.source,
      _1709: () => globalThis.firebase_firestore.startAfter,
      _1710: () => globalThis.firebase_firestore.startAt,
      _1711: () => globalThis.firebase_firestore.endBefore,
      _1712: () => globalThis.firebase_firestore.endAt,
      _1755: (x0,x1) => x0.item(x1),
      _1756: (x0,x1) => x0.querySelector(x1),
      _1757: x0 => globalThis.firebase_database.goOffline(x0),
      _1758: x0 => globalThis.firebase_database.goOnline(x0),
      _1760: (x0,x1) => globalThis.firebase_database.ref(x0,x1),
      _1762: (x0,x1) => globalThis.firebase_database.child(x0,x1),
      _1763: x0 => globalThis.firebase_database.onDisconnect(x0),
      _1766: (x0,x1) => globalThis.firebase_database.set(x0,x1),
      _1767: (x0,x1) => globalThis.firebase_database.update(x0,x1),
      _1770: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1770(f,arguments.length,x0) }),
      _1771: x0 => ({applyLocally: x0}),
      _1772: (x0,x1,x2) => globalThis.firebase_database.runTransaction(x0,x1,x2),
      _1773: x0 => globalThis.firebase_database.get(x0),
      _1784: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1784(f,arguments.length,x0,x1) }),
      _1785: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1785(f,arguments.length,x0) }),
      _1786: (x0,x1,x2) => globalThis.firebase_database.onChildAdded(x0,x1,x2),
      _1787: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1787(f,arguments.length,x0,x1) }),
      _1788: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1788(f,arguments.length,x0) }),
      _1789: (x0,x1,x2) => globalThis.firebase_database.onValue(x0,x1,x2),
      _1790: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1790(f,arguments.length,x0,x1) }),
      _1791: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1791(f,arguments.length,x0) }),
      _1792: (x0,x1,x2) => globalThis.firebase_database.onChildRemoved(x0,x1,x2),
      _1793: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1793(f,arguments.length,x0,x1) }),
      _1794: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1794(f,arguments.length,x0) }),
      _1795: (x0,x1,x2) => globalThis.firebase_database.onChildChanged(x0,x1,x2),
      _1796: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1796(f,arguments.length,x0,x1) }),
      _1797: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1797(f,arguments.length,x0) }),
      _1798: (x0,x1,x2) => globalThis.firebase_database.onChildMoved(x0,x1,x2),
      _1811: x0 => x0.toJSON(),
      _1820: x0 => x0.val(),
      _1821: x0 => x0.toJSON(),
      _1822: x0 => x0.cancel(),
      _1824: (x0,x1) => x0.set(x1),
      _1826: (x0,x1) => x0.update(x1),
      _1829: (x0,x1) => ({committed: x0,snapshot: x1}),
      _1830: (x0,x1) => globalThis.firebase_database.getDatabase(x0,x1),
      _1832: x0 => x0.decode(),
      _1833: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1834: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1835: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1835(f,arguments.length,x0) }),
      _1836: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1836(f,arguments.length,x0) }),
      _1837: x0 => x0.send(),
      _1838: () => new XMLHttpRequest(),
      _1839: x0 => x0.delete(),
      _1847: (x0,x1) => globalThis.firebase_auth.reauthenticateWithPopup(x0,x1),
      _1859: x0 => x0.toJSON(),
      _1860: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1860(f,arguments.length,x0) }),
      _1861: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1861(f,arguments.length,x0) }),
      _1862: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      _1863: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1863(f,arguments.length,x0) }),
      _1864: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1864(f,arguments.length,x0) }),
      _1865: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1865(f,arguments.length,x0) }),
      _1866: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1866(f,arguments.length,x0) }),
      _1867: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      _1884: (x0,x1) => globalThis.firebase_auth.signInWithPopup(x0,x1),
      _1886: x0 => x0.signOut(),
      _1887: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      _1902: () => new firebase_auth.GoogleAuthProvider(),
      _1903: (x0,x1) => x0.addScope(x1),
      _1904: (x0,x1) => x0.setCustomParameters(x1),
      _1906: x0 => new firebase_auth.OAuthProvider(x0),
      _1907: (x0,x1) => x0.addScope(x1),
      _1908: (x0,x1) => x0.setCustomParameters(x1),
      _1910: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      _1925: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      _1926: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      _1927: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      _1933: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      _1948: () => globalThis.firebase_auth.debugErrorMap,
      _1951: () => globalThis.firebase_auth.browserSessionPersistence,
      _1953: () => globalThis.firebase_auth.browserLocalPersistence,
      _1955: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      _1958: x0 => globalThis.firebase_auth.multiFactor(x0),
      _1959: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      _1961: x0 => x0.currentUser,
      _1965: x0 => x0.tenantId,
      _1975: x0 => x0.displayName,
      _1976: x0 => x0.email,
      _1977: x0 => x0.phoneNumber,
      _1978: x0 => x0.photoURL,
      _1979: x0 => x0.providerId,
      _1980: x0 => x0.uid,
      _1981: x0 => x0.emailVerified,
      _1982: x0 => x0.isAnonymous,
      _1983: x0 => x0.providerData,
      _1984: x0 => x0.refreshToken,
      _1985: x0 => x0.tenantId,
      _1986: x0 => x0.metadata,
      _1988: x0 => x0.providerId,
      _1989: x0 => x0.signInMethod,
      _1990: x0 => x0.accessToken,
      _1991: x0 => x0.idToken,
      _1992: x0 => x0.secret,
      _2004: x0 => x0.creationTime,
      _2005: x0 => x0.lastSignInTime,
      _2010: x0 => x0.code,
      _2012: x0 => x0.message,
      _2024: x0 => x0.email,
      _2025: x0 => x0.phoneNumber,
      _2026: x0 => x0.tenantId,
      _2049: x0 => x0.user,
      _2052: x0 => x0.providerId,
      _2053: x0 => x0.profile,
      _2054: x0 => x0.username,
      _2055: x0 => x0.isNewUser,
      _2058: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      _2063: x0 => x0.displayName,
      _2064: x0 => x0.enrollmentTime,
      _2065: x0 => x0.factorId,
      _2066: x0 => x0.uid,
      _2068: x0 => x0.hints,
      _2069: x0 => x0.session,
      _2071: x0 => x0.phoneNumber,
      _2083: (x0,x1) => x0.getItem(x1),
      _2088: (x0,x1) => x0.appendChild(x1),
      _2097: (x0,x1) => globalThis.firebase_app_check.getToken(x0,x1),
      _2099: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2099(f,arguments.length,x0) }),
      _2100: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2100(f,arguments.length,x0) }),
      _2101: (x0,x1,x2) => globalThis.firebase_app_check.onTokenChanged(x0,x1,x2),
      _2102: x0 => new firebase_app_check.ReCaptchaV3Provider(x0),
      _2103: x0 => new firebase_app_check.ReCaptchaEnterpriseProvider(x0),
      _2104: x0 => ({provider: x0}),
      _2105: (x0,x1) => globalThis.firebase_app_check.initializeAppCheck(x0,x1),
      _2106: (x0,x1,x2) => x0.setItem(x1,x2),
      _2107: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2107(f,arguments.length,x0,x1) }),
      _2111: x0 => x0.key,
      _2112: x0 => x0.priority,
      _2127: x0 => x0.committed,
      _2134: x0 => x0.ref,
      _2135: x0 => x0.committed,
      _2136: x0 => x0.snapshot,
      _2141: () => globalThis.firebase_core.getApps(),
      _2142: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7,recaptchaSiteKey: x8}),
      _2143: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      _2144: x0 => globalThis.firebase_core.getApp(x0),
      _2145: () => globalThis.firebase_core.getApp(),
      _2146: (x0,x1,x2) => globalThis.firebase_core.registerVersion(x0,x1,x2),
      _2147: (x0,x1) => x0.debug(x1),
      _2148: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2148(f,arguments.length,x0) }),
      _2149: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2149(f,arguments.length,x0,x1) }),
      _2150: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      _2151: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _2152: (x0,x1) => x0.createScriptURL(x1),
      _2153: (x0,x1,x2) => x0.createScript(x1,x2),
      _2154: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2154(f,arguments.length,x0) }),
      _2155: () => globalThis.firebase_core.SDK_VERSION,
      _2161: x0 => x0.apiKey,
      _2163: x0 => x0.authDomain,
      _2165: x0 => x0.databaseURL,
      _2167: x0 => x0.projectId,
      _2169: x0 => x0.storageBucket,
      _2171: x0 => x0.messagingSenderId,
      _2173: x0 => x0.measurementId,
      _2175: x0 => x0.appId,
      _2177: x0 => x0.recaptchaSiteKey,
      _2179: x0 => x0.name,
      _2180: x0 => x0.options,
      _2183: x0 => x0.token,
      _2187: () => new AudioContext(),
      _2188: (x0,x1) => x0.createMediaElementSource(x1),
      _2189: x0 => x0.createGain(),
      _2190: x0 => x0.createStereoPanner(),
      _2191: (x0,x1) => x0.connect(x1),
      _2192: x0 => x0.load(),
      _2193: x0 => x0.disconnect(),
      _2194: x0 => x0.resume(),
      _2195: x0 => x0.play(),
      _2196: x0 => x0.pause(),
      _2197: x0 => x0.close(),
      _2198: (x0,x1) => x0.removeItem(x1),
      _2199: () => globalThis.removeSplashFromWeb(),
      _2200: Date.now,
      _2202: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _2203: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _2204: () => typeof dartUseDateNowForTicks !== "undefined",
      _2205: () => 1000 * performance.now(),
      _2206: () => Date.now(),
      _2207: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _2208: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _2209: () => new WeakMap(),
      _2210: (map, o) => map.get(o),
      _2211: (map, o, v) => map.set(o, v),
      _2212: x0 => new WeakRef(x0),
      _2213: x0 => x0.deref(),
      _2214: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2214(f,arguments.length,x0) }),
      _2215: x0 => new FinalizationRegistry(x0),
      _2216: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _2218: (x0,x1) => x0.unregister(x1),
      _2220: () => globalThis.WeakRef,
      _2221: () => globalThis.FinalizationRegistry,
      _2223: s => JSON.stringify(s),
      _2224: s => printToConsole(s),
      _2225: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _2226: (o, p, r) => o.replaceAll(p, () => r),
      _2227: (o, p, r) => o.replace(p, () => r),
      _2228: Function.prototype.call.bind(String.prototype.toLowerCase),
      _2229: s => s.toUpperCase(),
      _2230: s => s.trim(),
      _2231: s => s.trimLeft(),
      _2232: s => s.trimRight(),
      _2233: (string, times) => string.repeat(times),
      _2234: Function.prototype.call.bind(String.prototype.indexOf),
      _2235: (s, p, i) => s.lastIndexOf(p, i),
      _2236: (string, token) => string.split(token),
      _2237: Object.is,
      _2241: (o, t) => typeof o === t,
      _2242: (o, c) => o instanceof c,
      _2243: o => Object.keys(o),
      _2246: (o,s,v) => o[s] = v,
      _2247: (o, a) => o + a,
      _2257: (o, a) => o == a,
      _2297: x0 => new Array(x0),
      _2299: x0 => x0.length,
      _2301: (x0,x1) => x0[x1],
      _2302: (x0,x1,x2) => { x0[x1] = x2 },
      _2305: (x0,x1,x2) => new DataView(x0,x1,x2),
      _2307: x0 => new Int8Array(x0),
      _2308: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _2310: x0 => new Uint8ClampedArray(x0),
      _2312: x0 => new Int16Array(x0),
      _2314: x0 => new Uint16Array(x0),
      _2316: x0 => new Int32Array(x0),
      _2318: x0 => new Uint32Array(x0),
      _2320: x0 => new Float32Array(x0),
      _2322: x0 => new Float64Array(x0),
      _2345: () => Symbol("jsBoxedDartObjectProperty"),
      _2346: x0 => x0.random(),
      _2347: (x0,x1) => x0.getRandomValues(x1),
      _2348: () => globalThis.crypto,
      _2349: () => globalThis.Math,
      _2362: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2363: (handle) => clearTimeout(handle),
      _2364: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2365: (handle) => clearInterval(handle),
      _2366: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2367: () => Date.now(),
      _2368: () => new Error().stack,
      _2369: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _2370: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2371: (x0,x1) => x0.exec(x1),
      _2372: (x0,x1) => x0.test(x1),
      _2373: x0 => x0.pop(),
      _2375: o => o === undefined,
      _2377: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2379: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2380: o => o instanceof RegExp,
      _2381: (l, r) => l === r,
      _2382: o => o,
      _2383: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _2384: o => o,
      _2385: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _2386: o => o,
      _2387: b => !!b,
      _2388: o => o.length,
      _2390: (o, i) => o[i],
      _2391: f => f.dartFunction,
      _2392: () => ({}),
      _2393: () => [],
      _2395: () => globalThis,
      _2396: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2397: (o, p) => p in o,
      _2398: (o, p) => o[p],
      _2399: (o, p, v) => o[p] = v,
      _2400: (o, m, a) => o[m].apply(o, a),
      _2402: o => String(o),
      _2403: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2404: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2404(f,arguments.length,x0) }),
      _2405: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2405(f,arguments.length,x0,x1) }),
      _2406: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _2407: o => [o],
      _2408: (o0, o1) => [o0, o1],
      _2409: (o0, o1, o2) => [o0, o1, o2],
      _2410: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2411: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _2412: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2413: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2414: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2415: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2416: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2417: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2418: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2419: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2420: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2421: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2422: x0 => new ArrayBuffer(x0),
      _2423: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2425: x0 => x0.index,
      _2426: x0 => x0.groups,
      _2427: x0 => x0.flags,
      _2428: x0 => x0.multiline,
      _2429: x0 => x0.ignoreCase,
      _2430: x0 => x0.unicode,
      _2431: x0 => x0.dotAll,
      _2432: (x0,x1) => { x0.lastIndex = x1 },
      _2433: (o, p) => p in o,
      _2434: (o, p) => o[p],
      _2435: (o, p, v) => o[p] = v,
      _2436: (o, p) => delete o[p],
      _2437: x0 => x0.exports,
      _2438: (x0,x1) => globalThis.WebAssembly.instantiateStreaming(x0,x1),
      _2439: x0 => x0.instance,
      _2442: x0 => x0.buffer,
      _2445: x0 => x0.arrayBuffer(),
      _2447: x0 => x0.sqlite3_initialize(),
      _2449: (x0,x1,x2,x3,x4) => x0.sqlite3_open_v2(x1,x2,x3,x4),
      _2450: (x0,x1) => x0.sqlite3_close_v2(x1),
      _2451: (x0,x1,x2) => x0.sqlite3_extended_result_codes(x1,x2),
      _2452: (x0,x1) => x0.sqlite3_extended_errcode(x1),
      _2453: (x0,x1) => x0.sqlite3_errmsg(x1),
      _2454: (x0,x1) => x0.sqlite3_errstr(x1),
      _2455: (x0,x1) => x0.sqlite3_error_offset(x1),
      _2459: (x0,x1) => x0.sqlite3_last_insert_rowid(x1),
      _2460: (x0,x1) => x0.sqlite3_changes(x1),
      _2461: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_exec(x1,x2,x3,x4,x5),
      _2464: (x0,x1,x2,x3,x4,x5,x6) => x0.sqlite3_prepare_v3(x1,x2,x3,x4,x5,x6),
      _2465: (x0,x1) => x0.sqlite3_finalize(x1),
      _2466: (x0,x1) => x0.sqlite3_step(x1),
      _2467: (x0,x1) => x0.sqlite3_reset(x1),
      _2468: (x0,x1) => x0.sqlite3_stmt_isexplain(x1),
      _2470: (x0,x1) => x0.sqlite3_column_count(x1),
      _2471: (x0,x1) => x0.sqlite3_bind_parameter_count(x1),
      _2473: (x0,x1,x2) => x0.sqlite3_column_name(x1,x2),
      _2474: (x0,x1,x2,x3) => x0.sqlite3_bind_double(x1,x2,x3),
      _2475: (x0,x1,x2,x3) => x0.sqlite3_bind_int64(x1,x2,x3),
      _2476: (x0,x1,x2) => x0.sqlite3_bind_null(x1,x2),
      _2477: (x0,x1,x2) => x0.sqlite3_column_blob(x1,x2),
      _2478: (x0,x1,x2) => x0.sqlite3_column_double(x1,x2),
      _2479: (x0,x1,x2) => x0.sqlite3_column_int64(x1,x2),
      _2480: (x0,x1,x2) => x0.sqlite3_column_text(x1,x2),
      _2481: (x0,x1,x2) => x0.sqlite3_column_bytes(x1,x2),
      _2482: (x0,x1,x2) => x0.sqlite3_column_type(x1,x2),
      _2483: (x0,x1) => x0.sqlite3_value_blob(x1),
      _2484: (x0,x1) => x0.sqlite3_value_double(x1),
      _2485: (x0,x1) => x0.sqlite3_value_type(x1),
      _2486: (x0,x1) => x0.sqlite3_value_int64(x1),
      _2487: (x0,x1) => x0.sqlite3_value_text(x1),
      _2488: (x0,x1) => x0.sqlite3_value_bytes(x1),
      _2492: (x0,x1,x2,x3,x4) => x0.sqlite3_result_blob64(x1,x2,x3,x4),
      _2493: (x0,x1,x2) => x0.sqlite3_result_double(x1,x2),
      _2494: (x0,x1,x2,x3) => x0.sqlite3_result_error(x1,x2,x3),
      _2495: (x0,x1,x2) => x0.sqlite3_result_int64(x1,x2),
      _2496: (x0,x1) => x0.sqlite3_result_null(x1),
      _2497: (x0,x1,x2,x3,x4) => x0.sqlite3_result_text(x1,x2,x3,x4),
      _2498: (x0,x1,x2) => x0.sqlite3_result_subtype(x1,x2),
      _2501: (x0,x1) => x0.sqlite3session_delete(x1),
      _2505: (x0,x1) => x0.sqlite3changeset_finalize(x1),
      _2516: (x0,x1) => x0.dart_sqlite3_malloc(x1),
      _2517: (x0,x1) => x0.dart_sqlite3_free(x1),
      _2518: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_blob(x1,x2,x3,x4),
      _2519: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_text(x1,x2,x3,x4),
      _2520: (x0,x1,x2,x3) => x0.dart_sqlite3_register_vfs(x1,x2,x3),
      _2522: (x0,x1,x2,x3,x4,x5,x6) => x0.dart_sqlite3_create_function_v2(x1,x2,x3,x4,x5,x6),
      _2524: (x0,x1,x2) => x0.dart_sqlite3_updates(x1,x2),
      _2525: (x0,x1,x2) => x0.dart_sqlite3_commits(x1,x2),
      _2526: (x0,x1,x2) => x0.dart_sqlite3_rollbacks(x1,x2),
      _2531: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2531(f,arguments.length,x0) }),
      _2532: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2532(f,arguments.length,x0,x1) }),
      _2533: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._2533(f,arguments.length,x0,x1,x2,x3,x4) }),
      _2534: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2534(f,arguments.length,x0,x1,x2) }),
      _2535: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2535(f,arguments.length,x0,x1,x2,x3) }),
      _2536: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2536(f,arguments.length,x0,x1,x2,x3) }),
      _2537: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2537(f,arguments.length,x0,x1,x2) }),
      _2538: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2538(f,arguments.length,x0,x1) }),
      _2539: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2539(f,arguments.length,x0,x1) }),
      _2540: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2540(f,arguments.length,x0) }),
      _2541: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2541(f,arguments.length,x0,x1,x2,x3) }),
      _2542: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2542(f,arguments.length,x0,x1,x2,x3) }),
      _2543: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2543(f,arguments.length,x0,x1) }),
      _2544: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2544(f,arguments.length,x0,x1) }),
      _2545: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2545(f,arguments.length,x0,x1) }),
      _2546: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2546(f,arguments.length,x0,x1) }),
      _2547: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2547(f,arguments.length,x0,x1) }),
      _2548: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2548(f,arguments.length,x0,x1) }),
      _2549: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2549(f,arguments.length,x0) }),
      _2550: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2550(f,arguments.length,x0) }),
      _2551: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2551(f,arguments.length,x0) }),
      _2552: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._2552(f,arguments.length,x0,x1,x2,x3,x4) }),
      _2553: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2553(f,arguments.length,x0,x1,x2,x3) }),
      _2554: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2554(f,arguments.length,x0,x1,x2,x3) }),
      _2555: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2555(f,arguments.length,x0,x1,x2,x3) }),
      _2556: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2556(f,arguments.length,x0,x1) }),
      _2557: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2557(f,arguments.length,x0,x1) }),
      _2558: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._2558(f,arguments.length,x0,x1,x2,x3,x4) }),
      _2559: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2559(f,arguments.length,x0,x1) }),
      _2560: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2560(f,arguments.length,x0,x1) }),
      _2561: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2561(f,arguments.length,x0,x1,x2) }),
      _2565: x0 => new URL(x0),
      _2566: (x0,x1) => new URL(x0,x1),
      _2567: (x0,x1) => globalThis.fetch(x0,x1),
      _2568: (x0,x1,x2) => x0.postMessage(x1,x2),
      _2569: (x0,x1,x2) => x0.postMessage(x1,x2),
      _2571: (x0,x1) => ({i: x0,p: x1}),
      _2572: (x0,x1) => ({c: x0,r: x1}),
      _2573: x0 => x0.i,
      _2574: x0 => x0.p,
      _2575: x0 => x0.c,
      _2576: x0 => x0.r,
      _2577: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2577(f,arguments.length,x0) }),
      _2578: (x0,x1) => x0.postMessage(x1),
      _2579: x0 => x0.close(),
      _2581: x0 => new Worker(x0),
      _2583: x0 => x0.getDirectory(),
      _2584: x0 => ({create: x0}),
      _2585: (x0,x1,x2) => x0.getFileHandle(x1,x2),
      _2586: x0 => x0.createSyncAccessHandle(),
      _2587: x0 => x0.close(),
      _2590: x0 => x0.close(),
      _2593: (x0,x1,x2) => x0.open(x1,x2),
      _2597: (x0,x1,x2) => x0.getDirectoryHandle(x1,x2),
      _2602: x0 => ({create: x0}),
      _2607: (x0,x1) => new SharedWorker(x0,x1),
      _2608: x0 => x0.start(),
      _2609: x0 => x0.terminate(),
      _2610: () => new MessageChannel(),
      _2614: x0 => new SharedArrayBuffer(x0),
      _2615: x0 => ({at: x0}),
      _2616: x0 => x0.getSize(),
      _2617: (x0,x1) => x0.truncate(x1),
      _2618: x0 => x0.flush(),
      _2621: x0 => x0.synchronizationBuffer,
      _2622: x0 => x0.communicationBuffer,
      _2623: (x0,x1,x2,x3) => ({clientVersion: x0,root: x1,synchronizationBuffer: x2,communicationBuffer: x3}),
      _2624: (x0,x1) => globalThis.IDBKeyRange.bound(x0,x1),
      _2625: x0 => ({autoIncrement: x0}),
      _2626: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      _2627: x0 => ({unique: x0}),
      _2628: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      _2629: (x0,x1) => x0.createObjectStore(x1),
      _2630: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2630(f,arguments.length,x0) }),
      _2631: (x0,x1,x2) => x0.transaction(x1,x2),
      _2632: (x0,x1) => x0.objectStore(x1),
      _2634: (x0,x1) => x0.index(x1),
      _2635: x0 => x0.openKeyCursor(),
      _2636: (x0,x1) => x0.getKey(x1),
      _2637: (x0,x1) => ({name: x0,length: x1}),
      _2638: (x0,x1) => x0.put(x1),
      _2639: (x0,x1) => x0.get(x1),
      _2640: (x0,x1) => x0.openCursor(x1),
      _2641: x0 => globalThis.IDBKeyRange.only(x0),
      _2642: (x0,x1,x2) => x0.put(x1,x2),
      _2643: (x0,x1) => x0.update(x1),
      _2644: (x0,x1) => x0.delete(x1),
      _2645: x0 => x0.name,
      _2646: x0 => x0.length,
      _2649: x0 => x0.continue(),
      _2650: () => globalThis.indexedDB,
      _2651: () => globalThis.navigator,
      _2652: (x0,x1) => x0.read(x1),
      _2653: (x0,x1,x2) => x0.read(x1,x2),
      _2654: (x0,x1) => x0.write(x1),
      _2655: (x0,x1,x2) => x0.write(x1,x2),
      _2657: (x0,x1,x2) => globalThis.Atomics.wait(x0,x1,x2),
      _2659: (x0,x1,x2) => globalThis.Atomics.notify(x0,x1,x2),
      _2660: (x0,x1,x2) => globalThis.Atomics.store(x0,x1,x2),
      _2661: (x0,x1) => globalThis.Atomics.load(x0,x1),
      _2662: () => globalThis.Int32Array,
      _2664: () => globalThis.Uint8Array,
      _2666: () => globalThis.DataView,
      _2668: x0 => x0.byteLength,
      _2670: x0 => globalThis.BigInt(x0),
      _2671: x0 => globalThis.Number(x0),
      _2678: x0 => new BroadcastChannel(x0),
      _2679: x0 => globalThis.Array.isArray(x0),
      _2680: (x0,x1) => x0.postMessage(x1),
      _2682: (x0,x1) => ({kind: x0,table: x1}),
      _2683: x0 => x0.kind,
      _2684: x0 => x0.table,
      _2685: (x0,x1) => x0.getAllKeys(x1),
      _2686: (x0,x1) => x0.getAll(x1),
      _2687: (x0,x1) => x0.contains(x1),
      _2690: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2690(f,arguments.length,x0) }),
      _2691: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2691(f,arguments.length,x0) }),
      _2697: () => new XMLHttpRequest(),
      _2698: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _2702: x0 => x0.send(),
      _2704: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2704(f,arguments.length,x0) }),
      _2705: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2705(f,arguments.length,x0) }),
      _2710: (x0,x1) => x0.item(x1),
      _2711: (x0,x1) => x0.removeChild(x1),
      _2712: x0 => globalThis.URL.createObjectURL(x0),
      _2714: x0 => ({type: x0}),
      _2715: (x0,x1) => new Blob(x0,x1),
      _2717: () => new FileReader(),
      _2718: (x0,x1) => x0.readAsArrayBuffer(x1),
      _2719: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2719(f,arguments.length,x0) }),
      _2720: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2720(f,arguments.length,x0) }),
      _2721: x0 => x0.openCursor(),
      _2722: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2722(f,arguments.length,x0) }),
      _2723: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2723(f,arguments.length,x0) }),
      _2724: () => new AbortController(),
      _2725: x0 => x0.abort(),
      _2726: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _2727: (x0,x1) => globalThis.fetch(x0,x1),
      _2728: (x0,x1) => x0.get(x1),
      _2729: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2729(f,arguments.length,x0,x1,x2) }),
      _2730: (x0,x1) => x0.forEach(x1),
      _2731: x0 => x0.getReader(),
      _2732: x0 => x0.cancel(),
      _2733: x0 => x0.read(),
      _2734: x0 => x0.trustedTypes,
      _2735: (x0,x1) => { x0.src = x1 },
      _2736: (x0,x1) => x0.createScriptURL(x1),
      _2737: x0 => x0.nonce,
      _2738: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2738(f,arguments.length,x0) }),
      _2739: x0 => ({createScriptURL: x0}),
      _2740: (x0,x1) => x0.querySelectorAll(x1),
      _2741: (x0,x1) => x0.key(x1),
      _2742: x0 => x0.trustedTypes,
      _2743: (x0,x1) => { x0.text = x1 },
      _2744: o => o instanceof Array,
      _2745: (a, i) => a.splice(i, 1)[0],
      _2748: a => a.pop(),
      _2749: (a, i) => a.splice(i, 1),
      _2750: (a, s) => a.join(s),
      _2751: (a, s, e) => a.slice(s, e),
      _2753: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _2754: a => a.length,
      _2756: (a, i) => a[i],
      _2757: (a, i, v) => a[i] = v,
      _2759: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _2760: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2761: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof DataView) return 1;
        return 2;
      },
      _2762: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _2763: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2764: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _2765: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2766: o => o instanceof Uint8ClampedArray,
      _2767: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2768: o => o instanceof Uint16Array,
      _2769: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2770: o => o instanceof Int16Array,
      _2771: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2772: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _2773: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2774: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _2775: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2777: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2778: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _2779: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2780: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _2781: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2782: (a, i) => a.push(i),
      _2783: (t, s) => t.set(s),
      _2784: l => new DataView(new ArrayBuffer(l)),
      _2785: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2786: o => o.byteLength,
      _2787: o => o.buffer,
      _2788: o => o.byteOffset,
      _2789: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2790: (b, o) => new DataView(b, o),
      _2791: (b, o, l) => new DataView(b, o, l),
      _2792: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2793: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2794: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2795: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2796: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2797: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2798: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2799: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2800: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2801: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2802: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2803: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2806: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2807: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2808: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2809: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2810: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2811: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2812: Function.prototype.call.bind(Number.prototype.toString),
      _2813: Function.prototype.call.bind(BigInt.prototype.toString),
      _2814: Function.prototype.call.bind(Number.prototype.toString),
      _2815: (d, digits) => d.toFixed(digits),
      _2904: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      _2905: (module,f) => finalizeWrapper(f, function() { return module.exports._2905(f,arguments.length) }),
      _2954: (x0,x1) => { x0.responseType = x1 },
      _2955: x0 => x0.response,
      _3030: x0 => x0.style,
      _3229: (x0,x1) => { x0.nonce = x1 },
      _3389: (x0,x1) => { x0.download = x1 },
      _3414: (x0,x1) => { x0.href = x1 },
      _3633: x0 => x0.error,
      _3635: (x0,x1) => { x0.src = x1 },
      _3640: (x0,x1) => { x0.crossOrigin = x1 },
      _3643: (x0,x1) => { x0.preload = x1 },
      _3647: x0 => x0.currentTime,
      _3648: (x0,x1) => { x0.currentTime = x1 },
      _3649: x0 => x0.duration,
      _3654: (x0,x1) => { x0.playbackRate = x1 },
      _3663: (x0,x1) => { x0.loop = x1 },
      _3684: x0 => x0.code,
      _3685: x0 => x0.message,
      _4264: (x0,x1) => { x0.src = x1 },
      _4266: (x0,x1) => { x0.type = x1 },
      _4270: (x0,x1) => { x0.async = x1 },
      _4272: (x0,x1) => { x0.defer = x1 },
      _4274: (x0,x1) => { x0.crossOrigin = x1 },
      _4276: (x0,x1) => { x0.text = x1 },
      _4733: () => globalThis.window,
      _4772: x0 => x0.self,
      _4773: x0 => x0.document,
      _4776: x0 => x0.location,
      _4795: x0 => x0.navigator,
      _5052: x0 => x0.indexedDB,
      _5057: x0 => x0.trustedTypes,
      _5058: x0 => x0.sessionStorage,
      _5059: x0 => x0.localStorage,
      _5067: x0 => x0.href,
      _5074: x0 => x0.hostname,
      _5182: x0 => x0.userAgent,
      _5183: x0 => x0.vendor,
      _5195: x0 => x0.storage,
      _5233: x0 => x0.data,
      _5263: x0 => x0.port1,
      _5264: x0 => x0.port2,
      _5266: (x0,x1) => { x0.onmessage = x1 },
      _5344: x0 => x0.port,
      _5379: x0 => x0.length,
      _6766: x0 => x0.destination,
      _6770: x0 => x0.state,
      _6861: (x0,x1) => { x0.value = x1 },
      _7010: x0 => x0.gain,
      _7278: x0 => x0.type,
      _7279: x0 => x0.target,
      _7319: x0 => x0.signal,
      _7328: x0 => x0.length,
      _7330: x0 => x0.length,
      _7370: x0 => x0.baseURI,
      _7387: () => globalThis.document,
      _7467: x0 => x0.body,
      _7469: x0 => x0.head,
      _7800: (x0,x1) => { x0.id = x1 },
      _7827: x0 => x0.children,
      _9146: x0 => x0.value,
      _9148: x0 => x0.done,
      _9311: (x0,x1) => { x0.type = x1 },
      _9327: x0 => x0.result,
      _9823: x0 => x0.url,
      _9825: x0 => x0.status,
      _9827: x0 => x0.statusText,
      _9828: x0 => x0.headers,
      _9829: x0 => x0.body,
      _11283: x0 => x0.result,
      _11284: x0 => x0.error,
      _11289: (x0,x1) => { x0.onsuccess = x1 },
      _11291: (x0,x1) => { x0.onerror = x1 },
      _11295: (x0,x1) => { x0.onupgradeneeded = x1 },
      _11297: x0 => x0.oldVersion,
      _11312: x0 => x0.version,
      _11313: x0 => x0.objectStoreNames,
      _11375: x0 => x0.key,
      _11376: x0 => x0.primaryKey,
      _11378: x0 => x0.value,
      _12216: (x0,x1) => { x0.display = x1 },
      _13438: x0 => x0.name,
      _13439: x0 => x0.message,
      _14154: () => globalThis.console,
      _14177: () => globalThis.document,
      _14179: () => globalThis.console,
      _14184: (x0,x1) => { x0.height = x1 },
      _14186: (x0,x1) => { x0.width = x1 },
      _14188: (x0,x1) => { x0.pointerEvents = x1 },
      _14197: x0 => x0.style,
      _14200: x0 => x0.src,
      _14201: (x0,x1) => { x0.src = x1 },
      _14202: x0 => x0.naturalWidth,
      _14203: x0 => x0.naturalHeight,
      _14218: (x0,x1) => x0.error(x1),
      _14223: x0 => x0.status,
      _14224: (x0,x1) => { x0.responseType = x1 },
      _14226: x0 => x0.response,
      _14231: x0 => x0.name,
      _14232: x0 => x0.message,
      _14233: x0 => x0.code,
      _14235: x0 => x0.customData,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });
    dartInstance.exports.$setThisModule(dartInstance);

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
