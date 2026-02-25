package com.example.bevyapp

import com.google.androidgamesdk.GameActivity

class MainActivity : GameActivity() {
    companion object {
        init {
            System.loadLibrary("bevy_ci_template")
        }
    }
}
