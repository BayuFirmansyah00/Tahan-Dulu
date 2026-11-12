package id.tahandulu.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Pastikan cold start & notif tap selalu mulai dari SplashScreen (/) lalu
    // serahkan deep link ke FcmService setelah sesi terautentikasi.
    override fun getInitialRoute(): String = "/"

    override fun shouldHandleDeeplinking(): Boolean = false
}

