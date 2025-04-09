package io.flutter.app;

import androidx.multidex.MultiDexApplication;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterMain;

/**
 * Flutter's default Application class that extends from {@link androidx.multidex.MultiDexApplication}
 * to enable multidex support.
 */
public class FlutterMultiDexApplication extends MultiDexApplication implements PluginRegistrantCallback {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
    }

    @Override
    public void registerWith(PluginRegistry registry) {
        GeneratedPluginRegistrant.registerWith(new FlutterEngine(this));
    }
} 