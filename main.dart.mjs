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
      _1376: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      _1379: x0 => x0.call(),
      _1403: x0 => x0.commit(),
      _1404: (x0,x1) => x0.delete(x1),
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
      _1445: () => globalThis.firebase_firestore.serverTimestamp(),
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
      _1757: x0 => x0.decode(),
      _1758: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1759: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1760: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1760(f,arguments.length,x0) }),
      _1761: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1761(f,arguments.length,x0) }),
      _1762: x0 => x0.send(),
      _1763: () => new XMLHttpRequest(),
      _1764: x0 => x0.delete(),
      _1772: (x0,x1) => globalThis.firebase_auth.reauthenticateWithPopup(x0,x1),
      _1784: x0 => x0.toJSON(),
      _1785: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1785(f,arguments.length,x0) }),
      _1786: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1786(f,arguments.length,x0) }),
      _1787: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      _1788: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1788(f,arguments.length,x0) }),
      _1789: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1789(f,arguments.length,x0) }),
      _1790: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1790(f,arguments.length,x0) }),
      _1791: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1791(f,arguments.length,x0) }),
      _1792: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      _1809: (x0,x1) => globalThis.firebase_auth.signInWithPopup(x0,x1),
      _1811: x0 => x0.signOut(),
      _1812: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      _1827: () => new firebase_auth.GoogleAuthProvider(),
      _1828: (x0,x1) => x0.addScope(x1),
      _1829: (x0,x1) => x0.setCustomParameters(x1),
      _1831: x0 => new firebase_auth.OAuthProvider(x0),
      _1832: (x0,x1) => x0.addScope(x1),
      _1833: (x0,x1) => x0.setCustomParameters(x1),
      _1835: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      _1850: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      _1851: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      _1852: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      _1858: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      _1873: () => globalThis.firebase_auth.debugErrorMap,
      _1876: () => globalThis.firebase_auth.browserSessionPersistence,
      _1878: () => globalThis.firebase_auth.browserLocalPersistence,
      _1880: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      _1883: x0 => globalThis.firebase_auth.multiFactor(x0),
      _1884: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      _1886: x0 => x0.currentUser,
      _1890: x0 => x0.tenantId,
      _1900: x0 => x0.displayName,
      _1901: x0 => x0.email,
      _1902: x0 => x0.phoneNumber,
      _1903: x0 => x0.photoURL,
      _1904: x0 => x0.providerId,
      _1905: x0 => x0.uid,
      _1906: x0 => x0.emailVerified,
      _1907: x0 => x0.isAnonymous,
      _1908: x0 => x0.providerData,
      _1909: x0 => x0.refreshToken,
      _1910: x0 => x0.tenantId,
      _1911: x0 => x0.metadata,
      _1913: x0 => x0.providerId,
      _1914: x0 => x0.signInMethod,
      _1915: x0 => x0.accessToken,
      _1916: x0 => x0.idToken,
      _1917: x0 => x0.secret,
      _1924: x0 => x0.providerId,
      _1929: x0 => x0.creationTime,
      _1930: x0 => x0.lastSignInTime,
      _1935: x0 => x0.code,
      _1937: x0 => x0.message,
      _1949: x0 => x0.email,
      _1950: x0 => x0.phoneNumber,
      _1951: x0 => x0.tenantId,
      _1974: x0 => x0.user,
      _1977: x0 => x0.providerId,
      _1978: x0 => x0.profile,
      _1979: x0 => x0.username,
      _1980: x0 => x0.isNewUser,
      _1983: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      _1988: x0 => x0.displayName,
      _1989: x0 => x0.enrollmentTime,
      _1990: x0 => x0.factorId,
      _1991: x0 => x0.uid,
      _1993: x0 => x0.hints,
      _1994: x0 => x0.session,
      _1996: x0 => x0.phoneNumber,
      _2008: (x0,x1) => x0.getItem(x1),
      _2013: (x0,x1) => x0.appendChild(x1),
      _2024: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2024(f,arguments.length,x0) }),
      _2025: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2025(f,arguments.length,x0) }),
      _2026: (x0,x1,x2) => globalThis.firebase_app_check.onTokenChanged(x0,x1,x2),
      _2027: x0 => new firebase_app_check.ReCaptchaV3Provider(x0),
      _2028: x0 => new firebase_app_check.ReCaptchaEnterpriseProvider(x0),
      _2029: x0 => ({provider: x0}),
      _2030: (x0,x1) => globalThis.firebase_app_check.initializeAppCheck(x0,x1),
      _2031: (x0,x1,x2) => x0.setItem(x1,x2),
      _2034: () => globalThis.firebase_core.getApps(),
      _2035: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7,recaptchaSiteKey: x8}),
      _2036: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      _2037: x0 => globalThis.firebase_core.getApp(x0),
      _2038: () => globalThis.firebase_core.getApp(),
      _2039: (x0,x1,x2) => globalThis.firebase_core.registerVersion(x0,x1,x2),
      _2040: (x0,x1) => x0.debug(x1),
      _2041: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2041(f,arguments.length,x0) }),
      _2042: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2042(f,arguments.length,x0,x1) }),
      _2043: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      _2044: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _2045: (x0,x1) => x0.createScriptURL(x1),
      _2046: (x0,x1,x2) => x0.createScript(x1,x2),
      _2047: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2047(f,arguments.length,x0) }),
      _2048: () => globalThis.firebase_core.SDK_VERSION,
      _2054: x0 => x0.apiKey,
      _2056: x0 => x0.authDomain,
      _2058: x0 => x0.databaseURL,
      _2060: x0 => x0.projectId,
      _2062: x0 => x0.storageBucket,
      _2064: x0 => x0.messagingSenderId,
      _2066: x0 => x0.measurementId,
      _2068: x0 => x0.appId,
      _2070: x0 => x0.recaptchaSiteKey,
      _2072: x0 => x0.name,
      _2073: x0 => x0.options,
      _2076: x0 => x0.token,
      _2080: (x0,x1) => x0.removeItem(x1),
      _2081: () => globalThis.removeSplashFromWeb(),
      _2082: Date.now,
      _2084: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _2085: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _2086: () => typeof dartUseDateNowForTicks !== "undefined",
      _2087: () => 1000 * performance.now(),
      _2088: () => Date.now(),
      _2089: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _2090: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _2091: () => new WeakMap(),
      _2092: (map, o) => map.get(o),
      _2093: (map, o, v) => map.set(o, v),
      _2094: x0 => new WeakRef(x0),
      _2095: x0 => x0.deref(),
      _2096: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2096(f,arguments.length,x0) }),
      _2097: x0 => new FinalizationRegistry(x0),
      _2098: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _2100: (x0,x1) => x0.unregister(x1),
      _2102: () => globalThis.WeakRef,
      _2103: () => globalThis.FinalizationRegistry,
      _2105: s => JSON.stringify(s),
      _2106: s => printToConsole(s),
      _2107: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _2108: (o, p, r) => o.replaceAll(p, () => r),
      _2109: (o, p, r) => o.replace(p, () => r),
      _2110: Function.prototype.call.bind(String.prototype.toLowerCase),
      _2111: s => s.toUpperCase(),
      _2112: s => s.trim(),
      _2113: s => s.trimLeft(),
      _2114: s => s.trimRight(),
      _2115: (string, times) => string.repeat(times),
      _2116: Function.prototype.call.bind(String.prototype.indexOf),
      _2117: (s, p, i) => s.lastIndexOf(p, i),
      _2118: (string, token) => string.split(token),
      _2119: Object.is,
      _2123: (o, t) => typeof o === t,
      _2124: (o, c) => o instanceof c,
      _2125: o => Object.keys(o),
      _2129: (o, a) => o + a,
      _2139: (o, a) => o == a,
      _2179: x0 => new Array(x0),
      _2181: x0 => x0.length,
      _2183: (x0,x1) => x0[x1],
      _2184: (x0,x1,x2) => { x0[x1] = x2 },
      _2187: (x0,x1,x2) => new DataView(x0,x1,x2),
      _2189: x0 => new Int8Array(x0),
      _2190: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _2192: x0 => new Uint8ClampedArray(x0),
      _2194: x0 => new Int16Array(x0),
      _2196: x0 => new Uint16Array(x0),
      _2198: x0 => new Int32Array(x0),
      _2200: x0 => new Uint32Array(x0),
      _2202: x0 => new Float32Array(x0),
      _2204: x0 => new Float64Array(x0),
      _2228: x0 => x0.random(),
      _2229: (x0,x1) => x0.getRandomValues(x1),
      _2230: () => globalThis.crypto,
      _2231: () => globalThis.Math,
      _2244: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2245: (handle) => clearTimeout(handle),
      _2246: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2247: (handle) => clearInterval(handle),
      _2248: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2249: () => Date.now(),
      _2250: () => new Error().stack,
      _2251: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _2252: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2253: (x0,x1) => x0.exec(x1),
      _2254: (x0,x1) => x0.test(x1),
      _2255: x0 => x0.pop(),
      _2257: o => o === undefined,
      _2259: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2261: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2262: o => o instanceof RegExp,
      _2263: (l, r) => l === r,
      _2264: o => o,
      _2265: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _2266: o => o,
      _2267: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _2268: o => o,
      _2269: b => !!b,
      _2270: o => o.length,
      _2272: (o, i) => o[i],
      _2273: f => f.dartFunction,
      _2274: () => ({}),
      _2275: () => [],
      _2277: () => globalThis,
      _2278: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2279: (o, p) => p in o,
      _2280: (o, p) => o[p],
      _2281: (o, p, v) => o[p] = v,
      _2282: (o, m, a) => o[m].apply(o, a),
      _2284: o => String(o),
      _2285: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2286: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2286(f,arguments.length,x0) }),
      _2287: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2287(f,arguments.length,x0,x1) }),
      _2288: o => {
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
      _2289: o => [o],
      _2290: (o0, o1) => [o0, o1],
      _2291: (o0, o1, o2) => [o0, o1, o2],
      _2292: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2293: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _2294: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2295: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2298: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2299: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2300: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2301: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2302: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2303: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2304: x0 => new ArrayBuffer(x0),
      _2305: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2307: x0 => x0.index,
      _2308: x0 => x0.groups,
      _2309: x0 => x0.flags,
      _2310: x0 => x0.multiline,
      _2311: x0 => x0.ignoreCase,
      _2312: x0 => x0.unicode,
      _2313: x0 => x0.dotAll,
      _2314: (x0,x1) => { x0.lastIndex = x1 },
      _2315: (o, p) => p in o,
      _2316: (o, p) => o[p],
      _2317: (o, p, v) => o[p] = v,
      _2318: (o, p) => delete o[p],
      _2319: x0 => x0.exports,
      _2320: (x0,x1) => globalThis.WebAssembly.instantiateStreaming(x0,x1),
      _2321: x0 => x0.instance,
      _2324: x0 => x0.buffer,
      _2327: x0 => x0.arrayBuffer(),
      _2329: x0 => x0.sqlite3_initialize(),
      _2331: (x0,x1,x2,x3,x4) => x0.sqlite3_open_v2(x1,x2,x3,x4),
      _2332: (x0,x1) => x0.sqlite3_close_v2(x1),
      _2333: (x0,x1,x2) => x0.sqlite3_extended_result_codes(x1,x2),
      _2334: (x0,x1) => x0.sqlite3_extended_errcode(x1),
      _2335: (x0,x1) => x0.sqlite3_errmsg(x1),
      _2336: (x0,x1) => x0.sqlite3_errstr(x1),
      _2337: (x0,x1) => x0.sqlite3_error_offset(x1),
      _2341: (x0,x1) => x0.sqlite3_last_insert_rowid(x1),
      _2342: (x0,x1) => x0.sqlite3_changes(x1),
      _2343: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_exec(x1,x2,x3,x4,x5),
      _2346: (x0,x1,x2,x3,x4,x5,x6) => x0.sqlite3_prepare_v3(x1,x2,x3,x4,x5,x6),
      _2347: (x0,x1) => x0.sqlite3_finalize(x1),
      _2348: (x0,x1) => x0.sqlite3_step(x1),
      _2349: (x0,x1) => x0.sqlite3_reset(x1),
      _2350: (x0,x1) => x0.sqlite3_stmt_isexplain(x1),
      _2352: (x0,x1) => x0.sqlite3_column_count(x1),
      _2353: (x0,x1) => x0.sqlite3_bind_parameter_count(x1),
      _2355: (x0,x1,x2) => x0.sqlite3_column_name(x1,x2),
      _2356: (x0,x1,x2,x3) => x0.sqlite3_bind_double(x1,x2,x3),
      _2357: (x0,x1,x2,x3) => x0.sqlite3_bind_int64(x1,x2,x3),
      _2358: (x0,x1,x2) => x0.sqlite3_bind_null(x1,x2),
      _2359: (x0,x1,x2) => x0.sqlite3_column_blob(x1,x2),
      _2360: (x0,x1,x2) => x0.sqlite3_column_double(x1,x2),
      _2361: (x0,x1,x2) => x0.sqlite3_column_int64(x1,x2),
      _2362: (x0,x1,x2) => x0.sqlite3_column_text(x1,x2),
      _2363: (x0,x1,x2) => x0.sqlite3_column_bytes(x1,x2),
      _2364: (x0,x1,x2) => x0.sqlite3_column_type(x1,x2),
      _2365: (x0,x1) => x0.sqlite3_value_blob(x1),
      _2366: (x0,x1) => x0.sqlite3_value_double(x1),
      _2367: (x0,x1) => x0.sqlite3_value_type(x1),
      _2368: (x0,x1) => x0.sqlite3_value_int64(x1),
      _2369: (x0,x1) => x0.sqlite3_value_text(x1),
      _2370: (x0,x1) => x0.sqlite3_value_bytes(x1),
      _2374: (x0,x1,x2,x3,x4) => x0.sqlite3_result_blob64(x1,x2,x3,x4),
      _2375: (x0,x1,x2) => x0.sqlite3_result_double(x1,x2),
      _2376: (x0,x1,x2,x3) => x0.sqlite3_result_error(x1,x2,x3),
      _2377: (x0,x1,x2) => x0.sqlite3_result_int64(x1,x2),
      _2378: (x0,x1) => x0.sqlite3_result_null(x1),
      _2379: (x0,x1,x2,x3,x4) => x0.sqlite3_result_text(x1,x2,x3,x4),
      _2380: (x0,x1,x2) => x0.sqlite3_result_subtype(x1,x2),
      _2383: (x0,x1) => x0.sqlite3session_delete(x1),
      _2387: (x0,x1) => x0.sqlite3changeset_finalize(x1),
      _2398: (x0,x1) => x0.dart_sqlite3_malloc(x1),
      _2399: (x0,x1) => x0.dart_sqlite3_free(x1),
      _2400: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_blob(x1,x2,x3,x4),
      _2401: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_text(x1,x2,x3,x4),
      _2402: (x0,x1,x2,x3) => x0.dart_sqlite3_register_vfs(x1,x2,x3),
      _2404: (x0,x1,x2,x3,x4,x5,x6) => x0.dart_sqlite3_create_function_v2(x1,x2,x3,x4,x5,x6),
      _2406: (x0,x1,x2) => x0.dart_sqlite3_updates(x1,x2),
      _2407: (x0,x1,x2) => x0.dart_sqlite3_commits(x1,x2),
      _2408: (x0,x1,x2) => x0.dart_sqlite3_rollbacks(x1,x2),
      _2413: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2413(f,arguments.length,x0) }),
      _2414: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2414(f,arguments.length,x0,x1) }),
      _2415: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._2415(f,arguments.length,x0,x1,x2,x3,x4) }),
      _2416: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2416(f,arguments.length,x0,x1,x2) }),
      _2417: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2417(f,arguments.length,x0,x1,x2,x3) }),
      _2418: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2418(f,arguments.length,x0,x1,x2,x3) }),
      _2419: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2419(f,arguments.length,x0,x1,x2) }),
      _2420: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2420(f,arguments.length,x0,x1) }),
      _2421: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2421(f,arguments.length,x0,x1) }),
      _2422: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2422(f,arguments.length,x0) }),
      _2423: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2423(f,arguments.length,x0,x1,x2,x3) }),
      _2424: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2424(f,arguments.length,x0,x1,x2,x3) }),
      _2425: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2425(f,arguments.length,x0,x1) }),
      _2426: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2426(f,arguments.length,x0,x1) }),
      _2427: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2427(f,arguments.length,x0,x1) }),
      _2428: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2428(f,arguments.length,x0,x1) }),
      _2429: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2429(f,arguments.length,x0,x1) }),
      _2430: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2430(f,arguments.length,x0,x1) }),
      _2431: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2431(f,arguments.length,x0) }),
      _2432: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2432(f,arguments.length,x0) }),
      _2433: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2433(f,arguments.length,x0) }),
      _2434: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._2434(f,arguments.length,x0,x1,x2,x3,x4) }),
      _2435: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2435(f,arguments.length,x0,x1,x2,x3) }),
      _2436: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2436(f,arguments.length,x0,x1,x2,x3) }),
      _2437: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._2437(f,arguments.length,x0,x1,x2,x3) }),
      _2438: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2438(f,arguments.length,x0,x1) }),
      _2439: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2439(f,arguments.length,x0,x1) }),
      _2440: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._2440(f,arguments.length,x0,x1,x2,x3,x4) }),
      _2441: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2441(f,arguments.length,x0,x1) }),
      _2442: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2442(f,arguments.length,x0,x1) }),
      _2443: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2443(f,arguments.length,x0,x1,x2) }),
      _2447: x0 => new URL(x0),
      _2448: (x0,x1) => new URL(x0,x1),
      _2449: (x0,x1) => globalThis.fetch(x0,x1),
      _2450: (x0,x1,x2) => x0.postMessage(x1,x2),
      _2451: (x0,x1,x2) => x0.postMessage(x1,x2),
      _2453: (x0,x1) => ({i: x0,p: x1}),
      _2454: (x0,x1) => ({c: x0,r: x1}),
      _2455: x0 => x0.i,
      _2456: x0 => x0.p,
      _2457: x0 => x0.c,
      _2458: x0 => x0.r,
      _2459: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2459(f,arguments.length,x0) }),
      _2460: (x0,x1) => x0.postMessage(x1),
      _2461: x0 => x0.close(),
      _2463: x0 => new Worker(x0),
      _2465: x0 => x0.getDirectory(),
      _2466: x0 => ({create: x0}),
      _2467: (x0,x1,x2) => x0.getFileHandle(x1,x2),
      _2468: x0 => x0.createSyncAccessHandle(),
      _2469: x0 => x0.close(),
      _2472: x0 => x0.close(),
      _2475: (x0,x1,x2) => x0.open(x1,x2),
      _2479: (x0,x1,x2) => x0.getDirectoryHandle(x1,x2),
      _2484: x0 => ({create: x0}),
      _2489: (x0,x1) => new SharedWorker(x0,x1),
      _2490: x0 => x0.start(),
      _2491: x0 => x0.terminate(),
      _2492: () => new MessageChannel(),
      _2496: x0 => new SharedArrayBuffer(x0),
      _2497: x0 => ({at: x0}),
      _2498: x0 => x0.getSize(),
      _2499: (x0,x1) => x0.truncate(x1),
      _2500: x0 => x0.flush(),
      _2503: x0 => x0.synchronizationBuffer,
      _2504: x0 => x0.communicationBuffer,
      _2505: (x0,x1,x2,x3) => ({clientVersion: x0,root: x1,synchronizationBuffer: x2,communicationBuffer: x3}),
      _2506: (x0,x1) => globalThis.IDBKeyRange.bound(x0,x1),
      _2507: x0 => ({autoIncrement: x0}),
      _2508: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      _2509: x0 => ({unique: x0}),
      _2510: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      _2511: (x0,x1) => x0.createObjectStore(x1),
      _2512: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2512(f,arguments.length,x0) }),
      _2513: (x0,x1,x2) => x0.transaction(x1,x2),
      _2514: (x0,x1) => x0.objectStore(x1),
      _2516: (x0,x1) => x0.index(x1),
      _2517: x0 => x0.openKeyCursor(),
      _2518: (x0,x1) => x0.getKey(x1),
      _2519: (x0,x1) => ({name: x0,length: x1}),
      _2520: (x0,x1) => x0.put(x1),
      _2521: (x0,x1) => x0.get(x1),
      _2522: (x0,x1) => x0.openCursor(x1),
      _2523: x0 => globalThis.IDBKeyRange.only(x0),
      _2524: (x0,x1,x2) => x0.put(x1,x2),
      _2525: (x0,x1) => x0.update(x1),
      _2526: (x0,x1) => x0.delete(x1),
      _2527: x0 => x0.name,
      _2528: x0 => x0.length,
      _2531: x0 => x0.continue(),
      _2532: () => globalThis.indexedDB,
      _2533: () => globalThis.navigator,
      _2534: (x0,x1) => x0.read(x1),
      _2535: (x0,x1,x2) => x0.read(x1,x2),
      _2536: (x0,x1) => x0.write(x1),
      _2537: (x0,x1,x2) => x0.write(x1,x2),
      _2539: (x0,x1,x2) => globalThis.Atomics.wait(x0,x1,x2),
      _2541: (x0,x1,x2) => globalThis.Atomics.notify(x0,x1,x2),
      _2542: (x0,x1,x2) => globalThis.Atomics.store(x0,x1,x2),
      _2543: (x0,x1) => globalThis.Atomics.load(x0,x1),
      _2544: () => globalThis.Int32Array,
      _2546: () => globalThis.Uint8Array,
      _2548: () => globalThis.DataView,
      _2550: x0 => x0.byteLength,
      _2552: x0 => globalThis.BigInt(x0),
      _2553: x0 => globalThis.Number(x0),
      _2560: x0 => new BroadcastChannel(x0),
      _2561: x0 => globalThis.Array.isArray(x0),
      _2562: (x0,x1) => x0.postMessage(x1),
      _2564: (x0,x1) => ({kind: x0,table: x1}),
      _2565: x0 => x0.kind,
      _2566: x0 => x0.table,
      _2567: (x0,x1) => x0.getAllKeys(x1),
      _2568: (x0,x1) => x0.getAll(x1),
      _2569: (x0,x1) => x0.contains(x1),
      _2572: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2572(f,arguments.length,x0) }),
      _2573: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2573(f,arguments.length,x0) }),
      _2579: () => new XMLHttpRequest(),
      _2580: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _2584: x0 => x0.send(),
      _2586: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2586(f,arguments.length,x0) }),
      _2587: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2587(f,arguments.length,x0) }),
      _2592: (x0,x1) => x0.item(x1),
      _2593: (x0,x1) => x0.removeChild(x1),
      _2594: x0 => globalThis.URL.createObjectURL(x0),
      _2596: x0 => ({type: x0}),
      _2597: (x0,x1) => new Blob(x0,x1),
      _2599: () => new FileReader(),
      _2600: (x0,x1) => x0.readAsArrayBuffer(x1),
      _2601: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2601(f,arguments.length,x0) }),
      _2602: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2602(f,arguments.length,x0) }),
      _2603: x0 => x0.openCursor(),
      _2604: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2604(f,arguments.length,x0) }),
      _2605: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2605(f,arguments.length,x0) }),
      _2606: () => new AbortController(),
      _2607: x0 => x0.abort(),
      _2608: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _2609: (x0,x1) => globalThis.fetch(x0,x1),
      _2610: (x0,x1) => x0.get(x1),
      _2611: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._2611(f,arguments.length,x0,x1,x2) }),
      _2612: (x0,x1) => x0.forEach(x1),
      _2613: x0 => x0.getReader(),
      _2614: x0 => x0.cancel(),
      _2615: x0 => x0.read(),
      _2616: x0 => x0.trustedTypes,
      _2617: (x0,x1) => { x0.src = x1 },
      _2618: (x0,x1) => x0.createScriptURL(x1),
      _2619: x0 => x0.nonce,
      _2620: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2620(f,arguments.length,x0) }),
      _2621: x0 => ({createScriptURL: x0}),
      _2622: (x0,x1) => x0.querySelectorAll(x1),
      _2623: (x0,x1) => x0.key(x1),
      _2624: x0 => x0.trustedTypes,
      _2625: (x0,x1) => { x0.text = x1 },
      _2626: o => o instanceof Array,
      _2627: (a, i) => a.splice(i, 1)[0],
      _2630: a => a.pop(),
      _2631: (a, i) => a.splice(i, 1),
      _2632: (a, s) => a.join(s),
      _2633: (a, s, e) => a.slice(s, e),
      _2635: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _2636: a => a.length,
      _2638: (a, i) => a[i],
      _2639: (a, i, v) => a[i] = v,
      _2641: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _2642: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2643: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof DataView) return 1;
        return 2;
      },
      _2644: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _2645: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2646: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _2647: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2648: o => o instanceof Uint8ClampedArray,
      _2649: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2650: o => o instanceof Uint16Array,
      _2651: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2652: o => o instanceof Int16Array,
      _2653: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2654: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _2655: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2656: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _2657: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2659: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2660: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _2661: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2662: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _2663: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2664: (a, i) => a.push(i),
      _2665: (t, s) => t.set(s),
      _2666: l => new DataView(new ArrayBuffer(l)),
      _2667: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2668: o => o.byteLength,
      _2669: o => o.buffer,
      _2670: o => o.byteOffset,
      _2671: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2672: (b, o) => new DataView(b, o),
      _2673: (b, o, l) => new DataView(b, o, l),
      _2674: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2675: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2676: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2677: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2678: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2679: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2680: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2681: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2682: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2683: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2684: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2685: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2688: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2689: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2690: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2691: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2692: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2693: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2694: Function.prototype.call.bind(Number.prototype.toString),
      _2695: Function.prototype.call.bind(BigInt.prototype.toString),
      _2696: Function.prototype.call.bind(Number.prototype.toString),
      _2697: (d, digits) => d.toFixed(digits),
      _2786: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      _2787: (module,f) => finalizeWrapper(f, function() { return module.exports._2787(f,arguments.length) }),
      _2836: (x0,x1) => { x0.responseType = x1 },
      _2837: x0 => x0.response,
      _2912: x0 => x0.style,
      _3111: (x0,x1) => { x0.nonce = x1 },
      _3271: (x0,x1) => { x0.download = x1 },
      _3296: (x0,x1) => { x0.href = x1 },
      _4149: (x0,x1) => { x0.src = x1 },
      _4151: (x0,x1) => { x0.type = x1 },
      _4155: (x0,x1) => { x0.async = x1 },
      _4157: (x0,x1) => { x0.defer = x1 },
      _4159: (x0,x1) => { x0.crossOrigin = x1 },
      _4161: (x0,x1) => { x0.text = x1 },
      _4618: () => globalThis.window,
      _4657: x0 => x0.self,
      _4658: x0 => x0.document,
      _4661: x0 => x0.location,
      _4680: x0 => x0.navigator,
      _4937: x0 => x0.indexedDB,
      _4942: x0 => x0.trustedTypes,
      _4943: x0 => x0.sessionStorage,
      _4944: x0 => x0.localStorage,
      _4959: x0 => x0.hostname,
      _5067: x0 => x0.userAgent,
      _5068: x0 => x0.vendor,
      _5080: x0 => x0.storage,
      _5118: x0 => x0.data,
      _5148: x0 => x0.port1,
      _5149: x0 => x0.port2,
      _5151: (x0,x1) => { x0.onmessage = x1 },
      _5229: x0 => x0.port,
      _5264: x0 => x0.length,
      _7168: x0 => x0.type,
      _7169: x0 => x0.target,
      _7209: x0 => x0.signal,
      _7218: x0 => x0.length,
      _7220: x0 => x0.length,
      _7260: x0 => x0.baseURI,
      _7277: () => globalThis.document,
      _7357: x0 => x0.body,
      _7359: x0 => x0.head,
      _7690: (x0,x1) => { x0.id = x1 },
      _7717: x0 => x0.children,
      _9036: x0 => x0.value,
      _9038: x0 => x0.done,
      _9201: (x0,x1) => { x0.type = x1 },
      _9217: x0 => x0.result,
      _9713: x0 => x0.url,
      _9715: x0 => x0.status,
      _9717: x0 => x0.statusText,
      _9718: x0 => x0.headers,
      _9719: x0 => x0.body,
      _11173: x0 => x0.result,
      _11174: x0 => x0.error,
      _11179: (x0,x1) => { x0.onsuccess = x1 },
      _11181: (x0,x1) => { x0.onerror = x1 },
      _11185: (x0,x1) => { x0.onupgradeneeded = x1 },
      _11187: x0 => x0.oldVersion,
      _11202: x0 => x0.version,
      _11203: x0 => x0.objectStoreNames,
      _11265: x0 => x0.key,
      _11266: x0 => x0.primaryKey,
      _11268: x0 => x0.value,
      _12106: (x0,x1) => { x0.display = x1 },
      _13328: x0 => x0.name,
      _13329: x0 => x0.message,
      _14044: () => globalThis.console,
      _14067: () => globalThis.document,
      _14069: () => globalThis.console,
      _14074: (x0,x1) => { x0.height = x1 },
      _14076: (x0,x1) => { x0.width = x1 },
      _14078: (x0,x1) => { x0.pointerEvents = x1 },
      _14087: x0 => x0.style,
      _14090: x0 => x0.src,
      _14091: (x0,x1) => { x0.src = x1 },
      _14092: x0 => x0.naturalWidth,
      _14093: x0 => x0.naturalHeight,
      _14108: (x0,x1) => x0.error(x1),
      _14113: x0 => x0.status,
      _14114: (x0,x1) => { x0.responseType = x1 },
      _14116: x0 => x0.response,
      _14121: x0 => x0.name,
      _14122: x0 => x0.message,
      _14123: x0 => x0.code,
      _14125: x0 => x0.customData,

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
