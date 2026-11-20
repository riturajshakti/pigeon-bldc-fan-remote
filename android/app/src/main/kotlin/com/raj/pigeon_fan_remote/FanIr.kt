package com.raj.pigeon_fan_remote

import android.content.Context
import android.hardware.ConsumerIrManager

object FanIr {
    const val FREQUENCY = 38000
    const val ADDRESS = 0

    const val POWER = 129
    const val SLEEP = 135
    const val REVERSE = 136
    const val LIGHT = 140
    const val BOOST = 142
    const val MINUS = 146
    const val PLUS = 149
    const val TIMER = 150

    private const val HEADER_MARK = 9000
    private const val HEADER_SPACE = 4500
    private const val BIT_MARK = 560
    private const val ONE_SPACE = 1690
    private const val ZERO_SPACE = 560
    private const val TRAILER_MARK = 560
    private const val GAP = 40000

    private const val MIN_SPEED = 1
    private const val MAX_SPEED = 5
    private const val STEP_GAP_MS = 1L

    fun encode(address: Int, command: Int): IntArray {
        val bits = ArrayList<Int>(32)
        appendByte(bits, address)
        appendByte(bits, address.inv() and 0xFF)
        appendByte(bits, command)
        appendByte(bits, command.inv() and 0xFF)

        val pattern = ArrayList<Int>(2 + bits.size * 2 + 2)
        pattern.add(HEADER_MARK)
        pattern.add(HEADER_SPACE)
        for (bit in bits) {
            pattern.add(BIT_MARK)
            pattern.add(if (bit == 1) ONE_SPACE else ZERO_SPACE)
        }
        pattern.add(TRAILER_MARK)
        pattern.add(GAP)
        return pattern.toIntArray()
    }

    private fun appendByte(out: MutableList<Int>, value: Int) {
        for (i in 0 until 8) {
            out.add((value shr i) and 1)
        }
    }

    fun selectSpeed(context: Context, level: Int) {
        repeat(MAX_SPEED) {
            if (!send(context, MINUS)) return
            Thread.sleep(STEP_GAP_MS)
        }
        repeat(level - MIN_SPEED) {
            if (!send(context, PLUS)) return
            Thread.sleep(STEP_GAP_MS)
        }
    }

    fun send(context: Context, command: Int): Boolean {
        val ir = context.getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager
        if (ir == null || !ir.hasIrEmitter()) return false
        return try {
            ir.transmit(FREQUENCY, encode(ADDRESS, command))
            true
        } catch (e: Exception) {
            false
        }
    }
}
