package com.capt.saffolder;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.UriPermission;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;

import androidx.annotation.NonNull;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/** Folder pilihan pengguna (SAF). Pemilih butuh layar; sisanya jalan juga di latar belakang. */
public class SafFolderPlugin implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
        PluginRegistry.ActivityResultListener {
    private static final int REQUEST_PICK = 0x5AF0;

    private MethodChannel channel;
    private Context context;
    private ExecutorService io;
    private final Handler main = new Handler(Looper.getMainLooper());
    private ActivityPluginBinding activity;
    private MethodChannel.Result pending;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        io = Executors.newSingleThreadExecutor();
        channel = new MethodChannel(binding.getBinaryMessenger(), "saf_folder");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        io.shutdown();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding;
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        if (activity != null) activity.removeActivityResultListener(this);
        activity = null;
    }

    private interface Task {
        Object run() throws Exception;
    }

    private void background(MethodChannel.Result result, Task task) {
        io.execute(() -> {
            try {
                final Object value = task.run();
                main.post(() -> result.success(value));
            } catch (SecurityException e) {
                main.post(() -> result.error("no_permission", e.getMessage(), null));
            } catch (FileNotFoundException | IllegalArgumentException e) {
                main.post(() -> result.error("not_found", e.getMessage(), null));
            } catch (IOException e) {
                final String code = String.valueOf(e.getMessage()).contains("ENOSPC") ? "no_space" : "io";
                main.post(() -> result.error(code, e.getMessage(), null));
            } catch (Exception e) {
                main.post(() -> result.error("io", e.getMessage(), null));
            }
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "pick":
                pick(result);
                break;
            case "accessible": {
                final String tree = call.argument("tree");
                background(result, () -> accessible(tree));
                break;
            }
            case "list": {
                final String tree = call.argument("tree");
                background(result, () -> list(tree));
                break;
            }
            case "write": {
                final String tree = call.argument("tree");
                final String name = call.argument("name");
                final byte[] bytes = call.argument("bytes");
                background(result, () -> write(tree, name, bytes));
                break;
            }
            case "delete": {
                final String doc = call.argument("doc");
                background(result, () -> DocumentsContract.deleteDocument(context.getContentResolver(), Uri.parse(doc)));
                break;
            }
            case "release": {
                final String tree = call.argument("tree");
                background(result, () -> {
                    context.getContentResolver().releasePersistableUriPermission(Uri.parse(tree),
                            Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                    return null;
                });
                break;
            }
            default:
                result.notImplemented();
        }
    }

    private void pick(MethodChannel.Result result) {
        if (activity == null) {
            result.error("no_activity", "Pemilih folder butuh layar", null);
            return;
        }
        if (pending != null) {
            result.error("busy", "Pemilih folder sedang terbuka", null);
            return;
        }
        pending = result;
        final Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
        activity.getActivity().startActivityForResult(intent, REQUEST_PICK);
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQUEST_PICK) return false;
        final MethodChannel.Result result = pending;
        pending = null;
        if (result == null) return true;
        final Uri uri = data == null ? null : data.getData();
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null);
            return true;
        }
        try {
            context.getContentResolver().takePersistableUriPermission(uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            final Map<String, Object> out = new HashMap<>();
            out.put("tree", uri.toString());
            out.put("label", label(uri));
            result.success(out);
        } catch (SecurityException e) {
            result.error("no_permission", e.getMessage(), null);
        }
        return true;
    }

    /** "primary:Documents/HitungIn" menjadi "Documents/HitungIn". */
    private static String label(Uri tree) {
        final String id = DocumentsContract.getTreeDocumentId(tree);
        final int colon = id.indexOf(':');
        return colon >= 0 && colon < id.length() - 1 ? id.substring(colon + 1) : id;
    }

    private boolean accessible(String tree) {
        final Uri uri = Uri.parse(tree);
        boolean granted = false;
        for (UriPermission p : context.getContentResolver().getPersistedUriPermissions()) {
            if (p.getUri().equals(uri) && p.isWritePermission()) granted = true;
        }
        if (!granted) return false;
        final Uri doc = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri));
        try (Cursor c = context.getContentResolver().query(doc,
                new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID}, null, null, null)) {
            return c != null && c.moveToFirst();
        } catch (RuntimeException e) {
            return false;
        }
    }

    private List<Map<String, Object>> list(String tree) throws FileNotFoundException {
        final Uri uri = Uri.parse(tree);
        final Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri));
        final List<Map<String, Object>> out = new ArrayList<>();
        try (Cursor c = context.getContentResolver().query(children, new String[]{
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_SIZE}, null, null, null)) {
            if (c == null) throw new FileNotFoundException("Folder tidak ditemukan");
            while (c.moveToNext()) {
                final Map<String, Object> m = new HashMap<>();
                m.put("doc", DocumentsContract.buildDocumentUriUsingTree(uri, c.getString(0)).toString());
                m.put("name", c.getString(1));
                m.put("size", c.isNull(2) ? 0L : c.getLong(2));
                out.add(m);
            }
        }
        return out;
    }

    /** Tulis ke berkas sementara, periksa ukurannya, baru menggantikan berkas bernama sama. */
    private Object write(String tree, String name, byte[] bytes) throws Exception {
        final ContentResolver cr = context.getContentResolver();
        final Uri uri = Uri.parse(tree);
        final Uri parent = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri));
        final String tmpName = name + ".tmp";
        for (Map<String, Object> f : list(tree)) {
            if (tmpName.equals(f.get("name"))) DocumentsContract.deleteDocument(cr, Uri.parse((String) f.get("doc")));
        }
        final Uri tmp = DocumentsContract.createDocument(cr, parent, "application/octet-stream", tmpName);
        if (tmp == null) throw new IOException("Berkas tidak bisa dibuat");
        try (OutputStream os = cr.openOutputStream(tmp, "wt")) {
            if (os == null) throw new IOException("Berkas tidak bisa ditulis");
            os.write(bytes);
        } catch (Exception e) {
            DocumentsContract.deleteDocument(cr, tmp);
            throw e;
        }
        long size = -1;
        try (Cursor c = cr.query(tmp, new String[]{DocumentsContract.Document.COLUMN_SIZE}, null, null, null)) {
            if (c != null && c.moveToFirst()) size = c.getLong(0);
        }
        if (size != bytes.length) {
            DocumentsContract.deleteDocument(cr, tmp);
            throw new IOException("Ukuran berkas tidak sama");
        }
        for (Map<String, Object> f : list(tree)) {
            if (name.equals(f.get("name"))) DocumentsContract.deleteDocument(cr, Uri.parse((String) f.get("doc")));
        }
        final Uri finalDoc = DocumentsContract.renameDocument(cr, tmp, name);
        return (finalDoc == null ? tmp : finalDoc).toString();
    }
}
