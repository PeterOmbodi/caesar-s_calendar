// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(
      await _compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

let _isCompileStreamingSupported;
async function _compileStreaming(source, builtins) {
  _isCompileStreamingSupported ??= WebAssembly.compileStreaming(
    new Response(
      new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),
      {headers: {'Content-Type': 'application/wasm'}},
    ),
    builtins,
  ).then(() => false, (e) => e instanceof WebAssembly.CompileError);
  if (await _isCompileStreamingSupported) {
    return WebAssembly.compileStreaming(source, builtins);
  }
  return WebAssembly.compile(await (await source).arrayBuffer(), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
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
            AB: b => !!b,
      AC: Function.prototype.call.bind(DataView.prototype.setInt16),
      AD: x0 => x0.height,
      AE: x0 => x0.computedStyleMap(),
      AF: x0 => x0.clientX,
      AG: (x0,x1) => x0.decode(x1),
      AH: (x0,x1) => x0.querySelectorAll(x1),
      AI: (x0,x1,x2) => x0.insertBefore(x1,x2),
      AJ: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      AK: x0 => x0.arrayBuffer(),
      AL: (x0,x1) => { x0.onerror = x1 },
      AM: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_blob(x1,x2,x3,x4),
      AN: () => globalThis.DataView,
      AO: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      AP: (x0,x1) => x0.getModifierState(x1),
      AQ: (x0,x1,x2) => x0.setAttribute(x1,x2),
      AR: x0 => x0.secret,
      AS: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      AT: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      AU: x0 => x0.docChanges(),
      AV: (x0,x1) => x0.connect(x1),
      B: s => printToConsole(s),
      BB: () => globalThis.document,
      BC: Function.prototype.call.bind(DataView.prototype.setUint16),
      BD: x0 => x0.width,
      BE: (x0,x1) => x0.get(x1),
      BF: x0 => x0.changedTouches,
      BG: (x0,x1) => x0.adoptText(x1),
      BH: (x0,x1) => x0.removeProperty(x1),
      BI: x0 => x0.id,
      BJ: x0 => new window.ImageDecoder(x0),
      BK: (x0,x1) => x0.transferFromImageBitmap(x1),
      BL: x0 => x0.error,
      BM: (x0,x1) => x0.dart_sqlite3_malloc(x1),
      BN: x0 => x0.communicationBuffer,
      BO: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      BP: x0 => x0.metaKey,
      BQ: () => globalThis.removeSplashFromWeb(),
      BR: x0 => x0.accessToken,
      BS: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      BT: (x0,x1,x2) => x0.set(x1,x2),
      BU: x0 => x0.docs,
      BV: x0 => x0.load(),
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      CC: Function.prototype.call.bind(DataView.prototype.setUint8),
      CD: x0 => x0.screen,
      CE: (o, p) => p in o,
      CF: x0 => x0.key,
      CG: x0 => x0.first(),
      CH: (x0,x1) => x0.add(x1),
      CI: x0 => x0.offsetHeight,
      CJ: x0 => x0.name,
      CK: x0 => x0.rasterEndMilliseconds,
      CL: (x0,x1) => { x0.onsuccess = x1 },
      CM: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_text(x1,x2,x3,x4),
      CN: () => globalThis.Int32Array,
      CO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return wasmFunction(f,arguments.length,x0,x1,x2,x3,x4) }),
      CP: x0 => x0.altKey,
      CQ: x0 => x0.message,
      CR: x0 => x0.signInMethod,
      CS: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      CT: x0 => globalThis.firebase_firestore.Timestamp.fromMillis(x0),
      CU: x0 => globalThis.firebase_firestore.getDocs(x0),
      CV: x0 => x0.destination,
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: (x0,x1) => x0.focus(x1),
      DC: Function.prototype.call.bind(DataView.prototype.setInt8),
      DD: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      DE: (x0,x1) => { x0.textContent = x1 },
      DF: x0 => x0.identifier,
      DG: x0 => x0.next(),
      DH: x0 => x0.data,
      DI: x0 => x0.offsetWidth,
      DJ: x0 => x0.repetitionCount,
      DK: x0 => x0.rasterStartMilliseconds,
      DL: x0 => x0.continue(),
      DM: (x0,x1,x2,x3) => x0.sqlite3_bind_double(x1,x2,x3),
      DN: x0 => x0.byteLength,
      DO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      DP: x0 => x0.ctrlKey,
      DQ: x0 => globalThis.firebase_database.goOnline(x0),
      DR: x0 => x0.providerId,
      DS: () => globalThis.firebase_auth.debugErrorMap,
      DT: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      DU: x0 => globalThis.firebase_firestore.getDocsFromServer(x0),
      DV: (x0,x1) => { x0.value = x1 },
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: () => ({}),
      EC: Function.prototype.call.bind(DataView.prototype.getInt8),
      ED: x0 => x0.tabIndex,
      EE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      EF: x0 => x0.touches,
      EG: x0 => x0.current(),
      EH: (x0,x1) => x0.removeAttribute(x1),
      EI: x0 => x0.stopPropagation(),
      EJ: x0 => x0.frameCount,
      EK: x0 => x0.imageBitmaps,
      EL: x0 => x0.result,
      EM: (x0,x1,x2,x3) => x0.sqlite3_bind_int64(x1,x2,x3),
      EN: x0 => x0.synchronizationBuffer,
      EO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      EP: x0 => x0.isComposing,
      EQ: (x0,x1) => globalThis.firebase_database.getDatabase(x0,x1),
      ER: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      ES: () => globalThis.firebase_auth.browserSessionPersistence,
      ET: () => globalThis.firebase_firestore.deleteField(),
      EU: x0 => globalThis.firebase_firestore.getDocsFromCache(x0),
      EV: x0 => x0.gain,
      F: () => new Error().stack,
      FB: (o, p, v) => o[p] = v,
      FC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      FD: (x0,x1) => x0.contains(x1),
      FE: x0 => x0.matches,
      FF: x0 => x0.pressure,
      FG: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      FH: (x0,x1) => { x0.value = x1 },
      FI: x0 => x0.disabled,
      FJ: x0 => x0.selectedTrack,
      FK: (x0,x1) => { x0.height = x1 },
      FL: x0 => x0.target,
      FM: x0 => globalThis.BigInt(x0),
      FN: (o, p, v) => o[p] = v,
      FO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      FP: x0 => x0.code,
      FQ: x0 => globalThis.firebase_core.getApp(x0),
      FR: x0 => x0.username,
      FS: () => globalThis.firebase_auth.browserLocalPersistence,
      FT: () => globalThis.firebase_firestore.serverTimestamp(),
      FU: x0 => x0.path,
      FV: x0 => x0.code,
      G: s => JSON.stringify(s),
      GB: () => [],
      GC: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      GD: x0 => x0.activeElement,
      GE: (x0,x1) => x0.matchMedia(x1),
      GF: x0 => x0.tiltY,
      GG: x0 => x0.v8BreakIterator,
      GH: (x0,x1) => { x0.value = x1 },
      GI: (x0,x1) => { x0.min = x1 },
      GJ: x0 => x0.completed,
      GK: (x0,x1) => { x0.width = x1 },
      GL: (x0,x1,x2) => x0.transaction(x1,x2),
      GM: (x0,x1,x2) => x0.sqlite3_bind_null(x1,x2),
      GN: (x0,x1,x2) => x0.postMessage(x1,x2),
      GO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      GP: x0 => x0.repeat,
      GQ: () => globalThis.firebase_core.getApp(),
      GR: x0 => x0.providerId,
      GS: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      GT: x0 => ({merge: x0}),
      GU: (x0,x1) => globalThis.firebase_firestore.collection(x0,x1),
      GV: x0 => x0.message,
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: (a, i) => a.push(i),
      HC: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      HD: x0 => x0.parentNode,
      HE: x0 => x0.matches,
      HF: x0 => x0.tiltX,
      HG: () => globalThis.Intl,
      HH: x0 => x0.value,
      HI: (x0,x1) => { x0.max = x1 },
      HJ: x0 => x0.ready,
      HK: x0 => x0.convertToBlob(),
      HL: (x0,x1) => x0.objectStore(x1),
      HM: (x0,x1) => x0.sqlite3_bind_parameter_count(x1),
      HN: x0 => new SharedArrayBuffer(x0),
      HO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      HP: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      HQ: x0 => x0.committed,
      HR: x0 => x0.profile,
      HS: (x0,x1) => globalThis.firebase_auth.signInWithPopup(x0,x1),
      HT: x0 => new firebase_firestore.FieldPath(x0),
      HU: (x0,x1) => globalThis.firebase_firestore.collectionGroup(x0,x1),
      HV: x0 => x0.error,
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: x0 => new Int8Array(x0),
      IC: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      ID: x0 => x0.tagName,
      IE: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      IF: x0 => x0.pointerType,
      IG: (x0,x1) => x0.segment(x1),
      IH: x0 => x0.selectionDirection,
      II: (x0,x1) => { x0.disabled = x1 },
      IJ: x0 => x0.tracks,
      IK: (x0,x1,x2) => new ImageData(x0,x1,x2),
      IL: (x0,x1) => x0.getAllKeys(x1),
      IM: (x0,x1) => x0.sqlite3_stmt_isexplain(x1),
      IN: (x0,x1,x2,x3) => ({clientVersion: x0,root: x1,synchronizationBuffer: x2,communicationBuffer: x3}),
      IO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return wasmFunction(f,arguments.length,x0,x1,x2,x3,x4) }),
      IP: (x0,x1) => x0.canShare(x1),
      IQ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      IR: x0 => x0.isNewUser,
      IS: x0 => x0.tenantId,
      IT: (x0,x1) => new firebase_firestore.FieldPath(x0,x1),
      IU: (x0,x1,x2) => x0.set(x1,x2),
      IV: x0 => x0.duration,
      J: (s, p, i) => s.lastIndexOf(p, i),
      JB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      JC: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      JD: x0 => x0.target,
      JE: f => f.dartFunction,
      JF: x0 => x0.pointerId,
      JG: x0 => x0.index,
      JH: x0 => x0.selectionStart,
      JI: (x0,x1) => { x0.scrollLeft = x1 },
      JJ: () => globalThis.window.ImageDecoder,
      JK: (x0,x1) => x0.getContext(x1),
      JL: x0 => x0.key,
      JM: (x0,x1) => x0.dart_sqlite3_free(x1),
      JN: x0 => x0.close(),
      JO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      JP: (x0,x1) => x0.share(x1),
      JQ: x0 => ({applyLocally: x0}),
      JR: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      JS: x0 => x0.currentUser,
      JT: (x0,x1,x2) => new firebase_firestore.FieldPath(x0,x1,x2),
      JU: (x0,x1) => x0.delete(x1),
      JV: (x0,x1) => { x0.playbackRate = x1 },
      K: o => o,
      KB: x0 => new Uint8Array(x0),
      KC: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      KD: x0 => x0.clientY,
      KE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      KF: x0 => x0.getCoalescedEvents(),
      KG: x0 => x0.next(),
      KH: x0 => x0.selectionEnd,
      KI: (x0,x1) => { x0.spellcheck = x1 },
      KJ: x0 => x0.status,
      KK: (x0,x1) => new OffscreenCanvas(x0,x1),
      KL: (o, t) => typeof o === t,
      KM: (x0,x1,x2,x3,x4,x5,x6) => x0.sqlite3_prepare_v3(x1,x2,x3,x4,x5,x6),
      KN: (x0,x1) => x0.truncate(x1),
      KO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      KP: x0 => x0.message,
      KQ: (x0,x1,x2) => globalThis.firebase_database.runTransaction(x0,x1,x2),
      KR: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      KS: x0 => x0.signOut(),
      KT: (x0,x1,x2,x3) => new firebase_firestore.FieldPath(x0,x1,x2,x3),
      KU: x0 => x0.commit(),
      KV: (x0,x1) => { x0.loop = x1 },
      L: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      LB: x0 => new Uint8ClampedArray(x0),
      LC: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      LD: x0 => x0.clientX,
      LE: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      LF: s => s.trimLeft(),
      LG: x0 => x0.value,
      LH: x0 => x0.value,
      LI: (x0,x1) => { x0.disabled = x1 },
      LJ: x0 => x0.response,
      LK: x0 => x0.allocationSize(),
      LL: x0 => x0.close(),
      LM: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_exec(x1,x2,x3,x4,x5),
      LN: x0 => x0.createSyncAccessHandle(),
      LO: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2) { return wasmFunction(f,arguments.length,x0,x1,x2) }),
      LP: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      LQ: (x0,x1) => ({committed: x0,snapshot: x1}),
      LR: x0 => x0.session,
      LS: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      LT: (x0,x1,x2,x3,x4) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4),
      LU: x0 => globalThis.firebase_firestore.writeBatch(x0),
      LV: (x0,x1) => { x0.crossOrigin = x1 },
      M: x0 => x0.index,
      MB: x0 => new Int16Array(x0),
      MC: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      MD: (x0,x1,x2) => x0.addEventListener(x1,x2),
      ME: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      MF: s => s.toUpperCase(),
      MG: x0 => x0.done,
      MH: x0 => x0.selectionDirection,
      MI: (a, i) => a.splice(i, 1),
      MJ: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      MK: (x0,x1) => x0.copyTo(x1),
      ML: (x0,x1) => x0.delete(x1),
      MM: (x0,x1) => x0.sqlite3_changes(x1),
      MN: x0 => ({create: x0}),
      MO: x0 => ({at: x0}),
      MP: x0 => x0.remove(),
      MQ: x0 => x0.toJSON(),
      MR: x0 => x0.phoneNumber,
      MS: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      MT: (x0,x1,x2,x3,x4,x5) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5),
      MU: x0 => x0.recaptchaSiteKey,
      MV: (x0,x1) => { x0.preload = x1 },
      N: o => String(o),
      NB: x0 => new Uint16Array(x0),
      NC: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      ND: (x0,x1,x2) => x0.setAttribute(x1,x2),
      NE: (o, i) => o[i],
      NF: x0 => x0.pop(),
      NG: (o, m, a) => o[m].apply(o, a),
      NH: x0 => x0.selectionStart,
      NI: a => a.pop(),
      NJ: (x0,x1) => { x0.responseType = x1 },
      NK: (x0,x1) => { x0.height = x1 },
      NL: (x0,x1,x2) => x0.put(x1,x2),
      NM: (x0,x1) => x0.sqlite3_last_insert_rowid(x1),
      NN: (x0,x1,x2) => x0.getFileHandle(x1,x2),
      NO: (x0,x1) => x0.read(x1),
      NP: (o, a) => o + a,
      NQ: x0 => x0.snapshot,
      NR: x0 => x0.uid,
      NS: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      NT: (x0,x1,x2,x3,x4,x5,x6) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6),
      NU: x0 => x0.measurementId,
      NV: x0 => x0.href,
      O: o => o === undefined,
      OB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      OC: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      OD: (x0,x1) => x0.closest(x1),
      OE: o => o.length,
      OF: x0 => x0.flags,
      OG: x0 => x0.iterator,
      OH: x0 => x0.selectionEnd,
      OI: x0 => new WeakRef(x0),
      OJ: () => new XMLHttpRequest(),
      OK: (x0,x1) => { x0.width = x1 },
      OL: (x0,x1) => x0.createObjectStore(x1),
      OM: x0 => globalThis.Number(x0),
      ON: x0 => ({create: x0}),
      OO: (x0,x1,x2) => x0.read(x1,x2),
      OP: (x0,x1) => { x0.display = x1 },
      OQ: x0 => x0.committed,
      OR: x0 => x0.enrollmentTime,
      OS: x0 => x0.name,
      OT: (x0,x1,x2,x3,x4,x5,x6,x7) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7),
      OU: x0 => x0.appId,
      OV: x0 => x0.extraAssets,
      P: (x0,x1) => x0.exec(x1),
      PB: x0 => new Int32Array(x0),
      PC: (x0,x1) => x0.querySelector(x1),
      PD: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      PE: o => {
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
      PF: (a, s) => a.join(s),
      PG: () => globalThis.Symbol,
      PH: (x0,x1) => { x0.name = x1 },
      PI: x0 => x0.deref(),
      PJ: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      PK: (x0,x1) => x0.toDataURL(x1),
      PL: x0 => x0.version,
      PM: (x0,x1,x2) => x0.sqlite3_column_name(x1,x2),
      PN: (x0,x1,x2) => x0.getDirectoryHandle(x1,x2),
      PO: (x0,x1) => x0.write(x1),
      PP: x0 => x0.style,
      PQ: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      PR: x0 => x0.factorId,
      PS: x0 => x0.sessionStorage,
      PT: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      PU: x0 => x0.messagingSenderId,
      PV: x0 => x0.fontManifest,
      Q: (x0,x1) => { x0.lastIndex = x1 },
      QB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      QC: (x0,x1) => x0.item(x1),
      QD: (handle) => clearTimeout(handle),
      QE: x0 => x0.language,
      QF: (x0,x1) => x0.error(x1),
      QG: (x0,x1) => new Intl.Segmenter(x0,x1),
      QH: (x0,x1) => { x0.placeholder = x1 },
      QI: () => globalThis.WeakRef,
      QJ: (x0,x1) => x0.item(x1),
      QK: (x0,x1,x2,x3) => x0.drawImage(x1,x2,x3),
      QL: x0 => x0.objectStoreNames,
      QM: (x0,x1,x2) => x0.sqlite3_column_blob(x1,x2),
      QN: x0 => x0.getDirectory(),
      QO: (x0,x1,x2) => x0.write(x1,x2),
      QP: (x0,x1) => ({files: x0,text: x1}),
      QQ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      QR: x0 => x0.displayName,
      QS: x0 => x0.hostname,
      QT: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      QU: x0 => x0.storageBucket,
      QV: x0 => x0.assetManifest,
      R: o => o,
      RB: x0 => new Uint32Array(x0),
      RC: x0 => x0.length,
      RD: x0 => x0.maxTouchPoints,
      RE: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      RF: () => globalThis.console,
      RG: x0 => x0.Segmenter,
      RH: (x0,x1) => { x0.autocomplete = x1 },
      RI: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      RJ: (x0,x1) => x0.removeChild(x1),
      RK: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => x0.drawImage(x1,x2,x3,x4,x5,x6,x7,x8,x9),
      RL: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      RM: (x0,x1,x2) => x0.sqlite3_column_bytes(x1,x2),
      RN: x0 => x0.storage,
      RO: x0 => x0.flush(),
      RP: x0 => ({files: x0}),
      RQ: (x0,x1,x2) => globalThis.firebase_database.onChildAdded(x0,x1,x2),
      RR: x0 => x0.hints,
      RS: x0 => x0.location,
      RT: () => globalThis.firebase_firestore.documentId(),
      RU: x0 => x0.databaseURL,
      RV: x0 => x0.buildConfig,
      S: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      SB: x0 => new Float32Array(x0),
      SC: (x0,x1) => x0.querySelectorAll(x1),
      SD: x0 => x0.platform,
      SE: () => globalThis.window.FinalizationRegistry,
      SF: s => s.trimRight(),
      SG: x0 => x0.buffer,
      SH: (x0,x1) => { x0.type = x1 },
      SI: (a, s, e) => a.slice(s, e),
      SJ: (x0,x1) => x0.appendChild(x1),
      SK: (x0,x1) => x0.getContext(x1),
      SL: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      SM: (x0,x1,x2) => x0.sqlite3_column_text(x1,x2),
      SN: () => globalThis.navigator,
      SO: x0 => x0.getSize(),
      SP: x0 => ({text: x0}),
      SQ: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      SR: x0 => x0.tenantId,
      SS: x0 => x0.token,
      ST: (x0,x1) => new firebase_firestore.Timestamp(x0,x1),
      SU: x0 => x0.authDomain,
      SV: x0 => x0.length,
      T: o => o instanceof RegExp,
      TB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      TC: (x0,x1) => x0.getAttribute(x1),
      TD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      TE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      TF: x0 => x0.blur(),
      TG: x0 => x0.wasmMemory,
      TH: (x0,x1) => { x0.name = x1 },
      TI: x0 => x0.naturalHeight,
      TJ: x0 => x0.click(),
      TK: x0 => x0.format,
      TL: (x0,x1) => { x0.onupgradeneeded = x1 },
      TM: (x0,x1,x2) => x0.sqlite3_column_double(x1,x2),
      TN: x0 => new URL(x0),
      TO: (x0,x1) => x0.openCursor(x1),
      TP: () => ({}),
      TQ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      TR: x0 => x0.phoneNumber,
      TS: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      TT: (x0,x1) => new firebase_firestore.GeoPoint(x0,x1),
      TU: x0 => x0.projectId,
      TV: x0 => x0.getReader(),
      U: (string, times) => string.repeat(times),
      UB: x0 => new Float64Array(x0),
      UC: x0 => x0.remove(),
      UD: Date.now,
      UE: x0 => new window.FinalizationRegistry(x0),
      UF: x0 => x0.button,
      UG: () => globalThis.window._flutter_skwasmInstance,
      UH: (x0,x1) => { x0.placeholder = x1 },
      UI: x0 => x0.naturalWidth,
      UJ: x0 => x0.length,
      UK: (x0,x1,x2,x3,x4) => x0.getImageData(x1,x2,x3,x4),
      UL: x0 => x0.indexedDB,
      UM: (x0,x1,x2) => x0.sqlite3_column_int64(x1,x2),
      UN: (x0,x1) => new URL(x0,x1),
      UO: x0 => x0.arrayBuffer(),
      UP: (x0,x1,x2) => new File(x0,x1,x2),
      UQ: (x0,x1,x2) => globalThis.firebase_database.onValue(x0,x1,x2),
      UR: x0 => x0.email,
      US: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      UT: x0 => globalThis.firebase_firestore.vector(x0),
      UU: x0 => x0.apiKey,
      UV: x0 => x0.value,
      V: o => o,
      VB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      VC: (x0,x1) => x0.appendChild(x1),
      VD: (x0,x1) => x0.contains(x1),
      VE: (x0,x1) => x0.unregister(x1),
      VF: (x0,x1) => x0.prepend(x1),
      VG: () => new TextDecoder(),
      VH: (x0,x1) => { x0.scrollTop = x1 },
      VI: (x0,x1) => x0.createElement(x1),
      VJ: x0 => x0.children,
      VK: x0 => x0.data,
      VL: x0 => x0.self,
      VM: (x0,x1,x2) => x0.sqlite3_column_type(x1,x2),
      VN: (x0,x1) => globalThis.fetch(x0,x1),
      VO: (x0,x1) => globalThis.IDBKeyRange.bound(x0,x1),
      VP: (x0,x1) => { x0.type = x1 },
      VQ: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      VR: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      VS: (x0,x1,x2) => globalThis.firebase_app_check.onTokenChanged(x0,x1,x2),
      VT: x0 => globalThis.firebase_firestore.Bytes.fromUint8Array(x0),
      VU: x0 => x0.options,
      VV: x0 => x0.done,
      W: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      WB: x0 => new ArrayBuffer(x0),
      WC: (x0,x1) => x0.append(x1),
      WD: (decoder, codeUnits) => decoder.decode(codeUnits),
      WE: x0 => x0.preventDefault(),
      WF: x0 => x0.parentElement,
      WG: (map, o, v) => map.set(o, v),
      WH: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      WI: (x0,x1) => { x0.pointerEvents = x1 },
      WJ: (x0,x1) => x0.createElement(x1),
      WK: (o, p) => p in o,
      WL: () => new MessageChannel(),
      WM: (x0,x1) => x0.sqlite3_column_count(x1),
      WN: (x0,x1) => x0.sqlite3session_delete(x1),
      WO: x0 => x0.length,
      WP: x0 => x0.userAgent,
      WQ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      WR: x0 => x0.customData,
      WS: x0 => new firebase_app_check.ReCaptchaV3Provider(x0),
      WT: (x0,x1) => globalThis.firebase_firestore.getFirestore(x0,x1),
      WU: () => globalThis.firebase_core.getApps(),
      WV: x0 => x0.read(),
      X: x0 => x0.dotAll,
      XB: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      XC: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      XD: () => new TextDecoder("utf-8", {fatal: true}),
      XE: x0 => x0.parent,
      XF: x0 => x0.innerHeight,
      XG: (map, o) => map.get(o),
      XH: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      XI: (x0,x1) => { x0.height = x1 },
      XJ: (x0,x1) => { x0.download = x1 },
      XK: x0 => x0.groups,
      XL: x0 => new BroadcastChannel(x0),
      XM: (x0,x1) => x0.sqlite3_close_v2(x1),
      XN: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      XO: (x0,x1) => x0.get(x1),
      XP: (x0,x1) => x0.removeItem(x1),
      XQ: (x0,x1,x2) => globalThis.firebase_database.onChildRemoved(x0,x1,x2),
      XR: x0 => x0.message,
      XS: x0 => new firebase_app_check.ReCaptchaEnterpriseProvider(x0),
      XT: () => globalThis.firebase_firestore.count(),
      XU: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7,recaptchaSiteKey: x8}),
      XV: x0 => x0.body,
      Y: x0 => x0.unicode,
      YB: (x0,x1,x2) => new DataView(x0,x1,x2),
      YC: x0 => x0.style,
      YD: () => new TextDecoder("utf-8", {fatal: false}),
      YE: x0 => x0.timeStamp,
      YF: x0 => x0.innerWidth,
      YG: () => new WeakMap(),
      YH: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      YI: (x0,x1) => { x0.width = x1 },
      YJ: (x0,x1) => { x0.href = x1 },
      YK: x0 => x0.abort(),
      YL: x0 => globalThis.Array.isArray(x0),
      YM: (x0,x1,x2) => x0.dart_sqlite3_rollbacks(x1,x2),
      YN: (x0,x1) => x0.unregister(x1),
      YO: (x0,x1) => x0.index(x1),
      YP: x0 => x0.localStorage,
      YQ: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      YR: x0 => x0.code,
      YS: x0 => ({provider: x0}),
      YT: x0 => globalThis.firebase_firestore.sum(x0),
      YU: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      YV: x0 => x0.assetBase,
      Z: x0 => x0.ignoreCase,
      ZB: (o, p) => o[p],
      ZC: x0 => x0.debugShowSemanticsNodes,
      ZD: (a, i, v) => a[i] = v,
      ZE: (x0,x1) => x0.hasAttribute(x1),
      ZF: x0 => x0.height,
      ZG: (d, digits) => d.toFixed(digits),
      ZH: x0 => x0.keyCode,
      ZI: x0 => x0.style,
      ZJ: () => globalThis.document,
      ZK: () => new AbortController(),
      ZL: x0 => x0.table,
      ZM: (x0,x1,x2) => x0.dart_sqlite3_commits(x1,x2),
      ZN: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      ZO: x0 => x0.openKeyCursor(),
      ZP: (x0,x1) => x0.getItem(x1),
      ZQ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      ZR: x0 => x0.code,
      ZS: (x0,x1) => globalThis.firebase_app_check.initializeAppCheck(x0,x1),
      ZT: x0 => globalThis.firebase_firestore.average(x0),
      ZU: () => globalThis.firebase_core.SDK_VERSION,
      ZV: x0 => x0.loader,
      a: x0 => x0.multiline,
      aB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      aC: (x0,x1) => x0.warn(x1),
      aD: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      aE: x0 => x0.type,
      aF: x0 => x0.width,
      aG: x0 => x0.maxHeight,
      aH: (x0,x1) => x0.scrollIntoView(x1),
      aI: (x0,x1) => { x0.src = x1 },
      aJ: (x0,x1) => x0.querySelector(x1),
      aK: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      aL: x0 => x0.kind,
      aM: (x0,x1,x2) => x0.dart_sqlite3_updates(x1,x2),
      aN: x0 => new FinalizationRegistry(x0),
      aO: x0 => x0.primaryKey,
      aP: (x0,x1) => x0.key(x1),
      aQ: (x0,x1,x2) => globalThis.firebase_database.onChildChanged(x0,x1,x2),
      aR: x0 => x0.name,
      aS: (x0,x1) => globalThis.firebase_app_check.getToken(x0,x1),
      aT: (x0,x1) => globalThis.firebase_firestore.getAggregateFromServer(x0,x1),
      aU: (x0,x1,x2) => globalThis.firebase_core.registerVersion(x0,x1,x2),
      aV: () => globalThis._flutter,
      b: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      bB: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      bC: x0 => x0.console,
      bD: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      bE: (x0,x1) => x0.getModifierState(x1),
      bF: x0 => x0.clientHeight,
      bG: x0 => x0.maxWidth,
      bH: x0 => x0.multiViewEnabled,
      bI: () => globalThis.document,
      bJ: x0 => x0.body,
      bK: (x0,x1) => globalThis.fetch(x0,x1),
      bL: x0 => x0.data,
      bM: (x0,x1,x2,x3,x4,x5,x6) => x0.dart_sqlite3_create_function_v2(x1,x2,x3,x4,x5,x6),
      bN: () => globalThis.FinalizationRegistry,
      bO: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      bP: x0 => x0.length,
      bQ: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      bR: (x0,x1) => globalThis.firebase_auth.reauthenticateWithPopup(x0,x1),
      bS: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      bT: x0 => x0.data(),
      bU: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      c: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      cB: o => o.byteOffset,
      cC: () => globalThis.window,
      cD: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      cE: x0 => x0.buttons,
      cF: x0 => x0.clientWidth,
      cG: x0 => x0.minHeight,
      cH: (x0,x1) => x0.replaceWith(x1),
      cI: x0 => x0.src,
      cJ: (x0,x1) => { x0.id = x1 },
      cK: (x0,x1) => x0.get(x1),
      cL: (x0,x1) => x0.postMessage(x1),
      cM: (x0,x1,x2,x3) => x0.sqlite3_result_error(x1,x2,x3),
      cN: (x0,x1) => x0.sqlite3changeset_finalize(x1),
      cO: x0 => ({autoIncrement: x0}),
      cP: (x0,x1,x2) => x0.setItem(x1,x2),
      cQ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      cR: (x0,x1) => x0.setCustomParameters(x1),
      cS: x0 => ({maxAttempts: x0}),
      cT: (x0,x1,x2) => globalThis.firebase_firestore.where(x0,x1,x2),
      cU: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      d: (x0,x1) => x0.didCreateEngineInitializer(x1),
      dB: o => o.buffer,
      dC: (o, c) => o instanceof c,
      dD: (s) => +s,
      dE: x0 => x0.ctrlKey,
      dF: x0 => x0.isConnected,
      dG: x0 => x0.minWidth,
      dH: (x0,x1) => { x0.className = x1 },
      dI: x0 => x0.decode(),
      dJ: () => new FileReader(),
      dK: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2) { return wasmFunction(f,arguments.length,x0,x1,x2) }),
      dL: (x0,x1) => ({kind: x0,table: x1}),
      dM: (x0,x1,x2) => x0.sqlite3_result_subtype(x1,x2),
      dN: x0 => x0.exports,
      dO: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      dP: x0 => x0.baseURI,
      dQ: (x0,x1,x2) => globalThis.firebase_database.onChildMoved(x0,x1,x2),
      dR: (x0,x1) => x0.addScope(x1),
      dS: (x0,x1,x2) => globalThis.firebase_firestore.runTransaction(x0,x1,x2),
      dT: (x0,x1) => globalThis.firebase_firestore.query(x0,x1),
      dU: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      e: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      eB: Function.prototype.call.bind(DataView.prototype.getUint8),
      eC: (x0,x1) => x0[x1],
      eD: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      eE: x0 => x0.getBoundingClientRect(),
      eF: x0 => x0.head,
      eG: x0 => x0.debugSkipFontRetryDelay,
      eH: (x0,x1) => { x0.tabIndex = x1 },
      eI: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      eJ: (x0,x1) => x0.readAsArrayBuffer(x1),
      eK: (x0,x1) => x0.forEach(x1),
      eL: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      eM: (x0,x1,x2,x3,x4) => x0.sqlite3_result_blob64(x1,x2,x3,x4),
      eN: (x0,x1) => globalThis.WebAssembly.instantiateStreaming(x0,x1),
      eO: x0 => ({unique: x0}),
      eP: x0 => x0.document,
      eQ: x0 => x0.priority,
      eR: () => new firebase_auth.GoogleAuthProvider(),
      eS: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      eT: () => globalThis.firebase_firestore.and,
      eU: (x0,x1) => x0.createScriptURL(x1),
      f: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      fB: (b, o) => new DataView(b, o),
      fC: x0 => x0.length,
      fD: s => s.trim(),
      fE: x0 => x0.y,
      fF: (x0,x1) => { x0.content = x1 },
      fG: x0 => x0.status,
      fH: (x0,x1) => { x0.action = x1 },
      fI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      fJ: x0 => x0.result,
      fK: x0 => x0.name,
      fL: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      fM: (x0,x1,x2,x3,x4) => x0.sqlite3_result_text(x1,x2,x3,x4),
      fN: x0 => x0.call(),
      fO: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      fP: (x0,x1) => x0.getAttribute(x1),
      fQ: x0 => x0.val(),
      fR: (x0,x1) => x0.setCustomParameters(x1),
      fS: (o,s,v) => o[s] = v,
      fT: () => globalThis.firebase_firestore.or,
      fU: (x0,x1,x2) => x0.createScript(x1,x2),
      g: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      gB: (b, o, l) => new DataView(b, o, l),
      gC: (string, token) => string.split(token),
      gD: x0 => x0.classList,
      gE: x0 => x0.x,
      gF: (x0,x1) => { x0.name = x1 },
      gG: (x0,x1,x2) => x0.set(x1,x2),
      gH: (x0,x1) => { x0.method = x1 },
      gI: (x0,x1,x2) => x0.addEventListener(x1,x2),
      gJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gK: x0 => x0.statusText,
      gL: (x0,x1) => x0.postMessage(x1),
      gM: (x0,x1,x2) => x0.sqlite3_result_double(x1,x2),
      gN: x0 => x0.instance,
      gO: x0 => x0.oldVersion,
      gP: (x0,x1) => x0.debug(x1),
      gQ: x0 => x0.key,
      gR: (x0,x1) => x0.addScope(x1),
      gS: () => Symbol("jsBoxedDartObjectProperty"),
      gT: x0 => globalThis.firebase_firestore.limitToLast(x0),
      gU: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      h: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      hB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      hC: o => o instanceof Array,
      hD: x0 => x0.relatedTarget,
      hE: x0 => x0.top,
      hF: (x0,x1) => x0.removeChild(x1),
      hG: x0 => x0.arrayBuffer(),
      hH: (x0,x1) => { x0.noValidate = x1 },
      hI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      hJ: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      hK: x0 => x0.url,
      hL: x0 => x0.close(),
      hM: (x0,x1,x2) => x0.sqlite3_result_int64(x1,x2),
      hN: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      hO: () => globalThis.indexedDB,
      hP: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      hQ: x0 => x0.toJSON(),
      hR: x0 => new firebase_auth.OAuthProvider(x0),
      hS: x0 => ({serverTimestamps: x0}),
      hT: x0 => globalThis.firebase_firestore.limit(x0),
      hU: (o, p) => delete o[p],
      i: x0 => new Promise(x0),
      iB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      iC: (a, i) => a[i],
      iD: x0 => x0.hasFocus(),
      iE: x0 => x0.left,
      iF: x0 => x0.firstChild,
      iG: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      iH: x0 => x0.click(),
      iI: x0 => x0.send(),
      iJ: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      iK: x0 => x0.status,
      iL: (x0,x1) => ({i: x0,p: x1}),
      iM: (x0,x1) => x0.sqlite3_result_null(x1),
      iN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      iO: (x0,x1) => ({name: x0,length: x1}),
      iP: x0 => ({createScriptURL: x0}),
      iQ: x0 => x0.ref,
      iR: x0 => x0.delete(),
      iS: x0 => x0.fromCache,
      iT: () => globalThis.firebase_firestore.endBefore,
      iU: (x0,x1) => { x0.text = x1 },
      j: (x0,x1,x2) => x0.call(x1,x2),
      jB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      jC: a => a.length,
      jD: x0 => x0.shiftKey,
      jE: x0 => x0.scrollTop,
      jF: x0 => x0.viewConstraints,
      jG: (x0,x1) => x0.fetch(x1),
      jH: (x0,x1) => x0.getElementsByClassName(x1),
      jI: x0 => x0.close(),
      jJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      jK: x0 => x0.getReader(),
      jL: () => new Array(),
      jM: (x0,x1) => x0.sqlite3_value_blob(x1),
      jN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return wasmFunction(f,arguments.length,x0,x1,x2,x3,x4) }),
      jO: (x0,x1) => x0.update(x1),
      jP: (x0,x1,x2) => x0.createPolicy(x1,x2),
      jQ: x0 => globalThis.firebase_database.get(x0),
      jR: x0 => x0.providerId,
      jS: x0 => x0.hasPendingWrites,
      jT: () => globalThis.firebase_firestore.endAt,
      jU: (x0,x1) => { x0.text = x1 },
      k: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      kB: (t, s) => t.set(s),
      kC: (x0,x1) => x0.test(x1),
      kD: x0 => x0.body,
      kE: x0 => x0.offsetTop,
      kF: x0 => x0.hostElement,
      kG: x0 => x0.fontFallbackBaseUrl,
      kH: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      kI: x0 => x0.height,
      kJ: () => new XMLHttpRequest(),
      kK: x0 => x0.read(),
      kL: (x0,x1) => ({c: x0,r: x1}),
      kM: (x0,x1) => x0.sqlite3_value_bytes(x1),
      kN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2) { return wasmFunction(f,arguments.length,x0,x1,x2) }),
      kO: x0 => x0.name,
      kP: (x0,x1) => x0.createScriptURL(x1),
      kQ: x0 => x0.cancel(),
      kR: x0 => x0.tenantId,
      kS: x0 => x0.metadata,
      kT: () => globalThis.firebase_firestore.startAfter,
      kU: x0 => x0.trustedTypes,
      l: x0 => new Array(x0),
      lB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      lC: x0 => x0.userAgent,
      lD: x0 => x0.visibilityState,
      lE: x0 => x0.scrollLeft,
      lF: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      lG: (handle) => clearInterval(handle),
      lH: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      lI: x0 => x0.width,
      lJ: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      lK: x0 => x0.value,
      lL: (x0,x1) => { x0.onmessage = x1 },
      lM: (x0,x1) => x0.sqlite3_value_text(x1),
      lN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      lO: x0 => globalThis.IDBKeyRange.only(x0),
      lP: x0 => x0.head,
      lQ: (x0,x1) => x0.set(x1),
      lR: x0 => x0.refreshToken,
      lS: x0 => x0.toArray(),
      lT: () => globalThis.firebase_firestore.startAt,
      lU: (x0,x1) => { x0.crossOrigin = x1 },
      m: o => [o],
      mB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      mC: x0 => x0.navigator,
      mD: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      mE: x0 => x0.offsetLeft,
      mF: x0 => ({runApp: x0}),
      mG: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      mH: (x0,x1) => x0.dispatchEvent(x1),
      mI: (x0,x1,x2,x3,x4,x5) => x0.createImageBitmap(x1,x2,x3,x4,x5),
      mJ: x0 => x0.send(),
      mK: x0 => x0.done,
      mL: (o, a) => o == a,
      mM: (x0,x1) => x0.sqlite3_value_double(x1),
      mN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      mO: (x0,x1) => x0.getKey(x1),
      mP: (x0,x1) => { x0.nonce = x1 },
      mQ: (x0,x1) => x0.update(x1),
      mR: x0 => x0.phoneNumber,
      mS: x0 => x0.toUint8Array(),
      mT: (x0,x1) => globalThis.firebase_firestore.orderBy(x0,x1),
      mU: (x0,x1) => { x0.type = x1 },
      n: (o0, o1) => [o0, o1],
      nB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      nC: Function.prototype.call.bind(String.prototype.toLowerCase),
      nD: x0 => x0.disconnect(),
      nE: x0 => x0.offsetParent,
      nF: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      nG: () => Date.now(),
      nH: (x0,x1) => x0.createEvent(x1),
      nI: (x0,x1) => x0.createImageBitmap(x1),
      nJ: x0 => x0.type,
      nK: x0 => x0.cancel(),
      nL: x0 => x0.r,
      nM: (x0,x1) => x0.sqlite3_value_int64(x1),
      nN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2) { return wasmFunction(f,arguments.length,x0,x1,x2) }),
      nO: (x0,x1) => x0.put(x1),
      nP: (x0,x1) => x0.querySelectorAll(x1),
      nQ: x0 => globalThis.firebase_database.onDisconnect(x0),
      nR: x0 => x0.lastSignInTime,
      nS: () => globalThis.firebase_firestore.Bytes,
      nT: x0 => globalThis.firebase_firestore.deleteDoc(x0),
      nU: x0 => x0.close(),
      o: (o0, o1, o2) => [o0, o1, o2],
      oB: Function.prototype.call.bind(DataView.prototype.getUint32),
      oC: Object.is,
      oD: x0 => new Intl.Locale(x0),
      oE: x0 => x0.offsetY,
      oF: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      oG: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      oH: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      oI: x0 => new Blob(x0),
      oJ: x0 => x0.response,
      oK: x0 => x0.body,
      oL: x0 => x0.c,
      oM: (x0,x1) => x0.sqlite3_value_type(x1),
      oN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      oO: (x0,x1,x2) => x0.postMessage(x1,x2),
      oP: (x0,x1) => x0.item(x1),
      oQ: (x0,x1) => globalThis.firebase_database.child(x0,x1),
      oR: x0 => x0.creationTime,
      oS: () => globalThis.firebase_firestore.VectorValue,
      oT: (x0,x1,x2) => globalThis.firebase_firestore.setDoc(x0,x1,x2),
      oU: x0 => x0.disconnect(),
      p: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      pB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      pC: x0 => x0.vendor,
      pD: x0 => x0.region,
      pE: x0 => x0.offsetX,
      pF: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      pG: x0 => x0.history,
      pH: x0 => x0.readText(),
      pI: x0 => x0.close(),
      pJ: (x0,x1) => { x0.responseType = x1 },
      pK: x0 => x0.headers,
      pL: x0 => x0.p,
      pM: (x0,x1,x2) => x0.sqlite3_extended_result_codes(x1,x2),
      pN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      pO: x0 => x0.port2,
      pP: x0 => x0.nonce,
      pQ: (x0,x1) => globalThis.firebase_database.set(x0,x1),
      pR: x0 => x0.metadata,
      pS: x0 => x0.longitude,
      pT: (x0,x1) => globalThis.firebase_firestore.setDoc(x0,x1),
      pU: (x0,x1) => { x0.src = x1 },
      q: (x0,x1,x2) => { x0[x1] = x2 },
      qB: Function.prototype.call.bind(DataView.prototype.getInt32),
      qC: (x0,x1) => x0.createTextNode(x1),
      qD: x0 => x0.script,
      qE: (o, p, r) => o.replace(p, () => r),
      qF: o => o.byteLength,
      qG: x0 => x0.search,
      qH: x0 => x0.clipboard,
      qI: x0 => x0.naturalHeight,
      qJ: x0 => x0.vendor,
      qK: x0 => x0.signal,
      qL: x0 => x0.i,
      qM: (x0,x1,x2,x3,x4) => x0.sqlite3_open_v2(x1,x2,x3,x4),
      qN: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      qO: x0 => x0.terminate(),
      qP: x0 => x0.length,
      qQ: (x0,x1) => globalThis.firebase_database.update(x0,x1),
      qR: x0 => x0.isAnonymous,
      qS: x0 => x0.latitude,
      qT: x0 => globalThis.firebase_firestore.getDoc(x0),
      qU: x0 => x0.pause(),
      r: (o, p) => o[p],
      rB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      rC: (x0,x1) => { x0.id = x1 },
      rD: x0 => x0.language,
      rE: (o, p, r) => o.replaceAll(p, () => r),
      rF: () => typeof dartUseDateNowForTicks !== "undefined",
      rG: x0 => x0.location,
      rH: (x0,x1) => x0.writeText(x1),
      rI: x0 => x0.naturalWidth,
      rJ: x0 => x0.navigator,
      rK: (x0,x1,x2) => x0.open(x1,x2),
      rL: x0 => x0.port1,
      rM: x0 => x0.sqlite3_initialize(),
      rN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      rO: (x0,x1) => new SharedWorker(x0,x1),
      rP: (x0,x1) => { x0.src = x1 },
      rQ: (x0,x1) => globalThis.firebase_database.ref(x0,x1),
      rR: x0 => x0.emailVerified,
      rS: () => globalThis.firebase_firestore.GeoPoint,
      rT: x0 => globalThis.firebase_firestore.getDocFromServer(x0),
      rU: x0 => x0.currentTime,
      s: () => globalThis,
      sB: o => o instanceof Uint16Array,
      sC: (x0,x1) => { x0.nonce = x1 },
      sD: x0 => x0.languages,
      sE: x0 => x0.deltaMode,
      sF: () => Date.now(),
      sG: x0 => x0.pathname,
      sH: x0 => x0.unlock(),
      sI: (x0,x1) => { x0.src = x1 },
      sJ: () => globalThis.window,
      sK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      sL: (x0,x1) => x0.sqlite3_finalize(x1),
      sM: (x0,x1,x2,x3) => x0.dart_sqlite3_register_vfs(x1,x2,x3),
      sN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return wasmFunction(f,arguments.length,x0,x1,x2,x3) }),
      sO: x0 => x0.start(),
      sP: (x0,x1) => { x0.src = x1 },
      sQ: x0 => globalThis.firebase_database.goOffline(x0),
      sR: x0 => x0.email,
      sS: (x0,x1) => x0.data(x1),
      sT: x0 => globalThis.firebase_firestore.getDocFromCache(x0),
      sU: x0 => x0.resume(),
      t: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      tB: Function.prototype.call.bind(DataView.prototype.getUint16),
      tC: x0 => x0.nonce,
      tD: (x0,x1) => x0.observe(x1),
      tE: x0 => x0.deltaY,
      tF: () => 1000 * performance.now(),
      tG: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      tH: (x0,x1) => x0.lock(x1),
      tI: x0 => x0.displayHeight,
      tJ: (x0,x1) => x0.getRandomValues(x1),
      tK: (x0,x1) => x0.contains(x1),
      tL: (x0,x1) => x0.sqlite3_reset(x1),
      tM: (x0,x1) => globalThis.Atomics.load(x0,x1),
      tN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      tO: x0 => x0.port,
      tP: (x0,x1) => { x0.defer = x1 },
      tQ: x0 => x0.displayName,
      tR: x0 => globalThis.firebase_auth.multiFactor(x0),
      tS: x0 => x0.nanoseconds,
      tT: x0 => x0.source,
      tU: x0 => x0.play(),
      u: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      uB: o => o instanceof Int16Array,
      uC: () => globalThis.window.flutterConfiguration,
      uD: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      uE: x0 => x0.deltaX,
      uF: (x0,x1) => x0.requestAnimationFrame(x1),
      uG: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      uH: x0 => x0.orientation,
      uI: x0 => x0.displayWidth,
      uJ: () => globalThis.crypto,
      uK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      uL: x0 => x0.buffer,
      uM: (x0,x1,x2) => globalThis.Atomics.wait(x0,x1,x2),
      uN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      uO: x0 => x0.canvasKitMaximumSurfaces,
      uP: (x0,x1) => { x0.async = x1 },
      uQ: x0 => x0.photoURL,
      uR: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      uS: x0 => x0.seconds,
      uT: x0 => ({source: x0}),
      uU: (x0,x1) => { x0.currentTime = x1 },
      v: (x0,x1) => ({addView: x0,removeView: x1}),
      vB: Function.prototype.call.bind(DataView.prototype.getInt16),
      vC: (x0,x1) => x0.attachShadow(x1),
      vD: x0 => new ResizeObserver(x0),
      vE: x0 => x0.wheelDeltaY,
      vF: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      vG: o => Object.keys(o),
      vH: (x0,x1) => x0.querySelector(x1),
      vI: x0 => x0.duration,
      vJ: l => new DataView(new ArrayBuffer(l)),
      vK: (x0,x1) => x0.getAll(x1),
      vL: (x0,x1) => x0.sqlite3_errstr(x1),
      vM: (x0,x1,x2) => globalThis.Atomics.notify(x0,x1,x2),
      vN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      vO: x0 => x0.nextSibling,
      vP: x0 => x0.trustedTypes,
      vQ: x0 => x0.providerData,
      vR: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      vS: () => globalThis.firebase_firestore.Timestamp,
      vT: x0 => x0.metadata,
      vU: x0 => x0.state,
      w: (l, r) => l === r,
      wB: o => o instanceof Uint8ClampedArray,
      wC: (x0,x1) => x0.createElement(x1),
      wD: (x0,x1) => x0.getPropertyValue(x1),
      wE: x0 => x0.wheelDeltaX,
      wF: x0 => x0.now(),
      wG: x0 => x0.state,
      wH: (x0,x1) => { x0.title = x1 },
      wI: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      wJ: x0 => globalThis.URL.createObjectURL(x0),
      wK: x0 => x0.value,
      wL: (x0,x1) => x0.sqlite3_errmsg(x1),
      wM: (x0,x1,x2) => globalThis.Atomics.store(x0,x1,x2),
      wN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      wO: (x0,x1) => x0.debug(x1),
      wP: () => globalThis.console,
      wQ: x0 => x0.toJSON(),
      wR: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      wS: () => globalThis.firebase_firestore.DocumentReference,
      wT: x0 => x0.doc,
      wU: () => new AudioContext(),
      x: x0 => x0.random(),
      xB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      xC: x0 => x0.scale,
      xD: x0 => globalThis.parseFloat(x0),
      xE: x0 => x0.bottom,
      xF: x0 => x0.performance,
      xG: x0 => x0.hash,
      xH: (x0,x1) => x0.vibrate(x1),
      xI: (x0,x1) => x0.decode(x1),
      xJ: x0 => ({type: x0}),
      xK: x0 => x0.openCursor(),
      xL: (x0,x1) => x0.sqlite3_error_offset(x1),
      xM: x0 => new Worker(x0),
      xN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      xO: (a, i) => a.splice(i, 1)[0],
      xP: x0 => x0.trustedTypes,
      xQ: x0 => x0.uid,
      xR: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      xS: x0 => x0.path,
      xT: x0 => x0.newIndex,
      xU: (x0,x1) => x0.createMediaElementSource(x1),
      y: () => globalThis.Math,
      yB: Function.prototype.call.bind(DataView.prototype.setInt32),
      yC: x0 => x0.visualViewport,
      yD: (x0,x1) => x0.getComputedStyle(x1),
      yE: x0 => x0.right,
      yF: x0 => new Uint8Array(x0),
      yG: x0 => x0.state,
      yH: x0 => x0.content,
      yI: x0 => x0.image,
      yJ: (x0,x1) => new Blob(x0,x1),
      yK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      yL: (x0,x1) => x0.sqlite3_extended_errcode(x1),
      yM: () => globalThis.Uint8Array,
      yN: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      yO: x0 => x0.hostElement,
      yP: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      yQ: x0 => x0.user,
      yR: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      yS: x0 => x0.ref,
      yT: x0 => x0.oldIndex,
      yU: x0 => x0.createGain(),
      z: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      zB: Function.prototype.call.bind(DataView.prototype.setUint32),
      zC: x0 => x0.devicePixelRatio,
      zD: x0 => x0.documentElement,
      zE: x0 => x0.clientY,
      zF: (x0,x1,x2) => x0.slice(x1,x2),
      zG: (x0,x1) => x0.go(x1),
      zH: x0 => x0.document,
      zI: x0 => x0.close(),
      zJ: (x0,x1,x2,x3) => x0.putImageData(x1,x2,x3),
      zK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      zL: (x0,x1) => x0.sqlite3_step(x1),
      zM: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof DataView) return 1;
        return 2;
      },
      zN: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      zO: x0 => x0.location,
      zP: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      zQ: x0 => x0.idToken,
      zR: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      zS: (x0,x1) => x0.get(x1),
      zT: x0 => x0.type,
      zU: x0 => x0.createStereoPanner(),

    };

    const baseImports = {
      _: dart2wasm,
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

    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
    });

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
