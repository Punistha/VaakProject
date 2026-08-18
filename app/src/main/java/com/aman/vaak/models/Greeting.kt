package com.aman.vaak.models

/**
 * Builds greeting messages shown to the user.
 */
object Greeting {
    private const val APP_NAME = "VaaK"

    /**
     * Returns a greeting for the given name, falling back to a generic
     * greeting when the name is blank.
     */
    fun greet(name: String = ""): String =
        if (name.isBlank()) {
            "Hello from $APP_NAME!"
        } else {
            "Hello, ${name.trim()}, from $APP_NAME!"
        }
}
