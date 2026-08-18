package com.aman.vaak.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class GreetingTest {
    @Test
    fun `greets given name`() {
        assertEquals("Hello, Punistha, from VaaK!", Greeting.greet("Punistha"))
    }

    @Test
    fun `trims surrounding whitespace from name`() {
        assertEquals("Hello, Punistha, from VaaK!", Greeting.greet("  Punistha  "))
    }

    @Test
    fun `falls back to generic greeting when name is blank`() {
        assertEquals("Hello from VaaK!", Greeting.greet())
        assertEquals("Hello from VaaK!", Greeting.greet("   "))
    }
}
