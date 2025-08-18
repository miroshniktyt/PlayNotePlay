//
//  AudioEngine.swift
//  music
//
//  Created by pc on 06.08.25.
//


import SwiftUI
import AVFoundation
import Combine

class AudioEngine: ObservableObject {
    var engine: AVAudioEngine
    var mixer: AVAudioMixerNode

    init() {
        engine = AVAudioEngine()
        mixer = engine.mainMixerNode
        setupAudioSession()
        startEngine()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func startEngine() {
        do {
            try engine.start()
        } catch {
            print("Engine start failed: \(error)")
        }
    }

    func createTone(frequency: Double, duration: Double, volume: Float = 0.3) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let frames = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!,
            frameCapacity: frames
        ) else { return nil }
        
        buffer.frameLength = frames
        
        let channelData = buffer.floatChannelData![0]
        let omega = 2.0 * Double.pi * frequency / sampleRate
        
        for frame in 0..<Int(frames) {
            let sample = Float(sin(omega * Double(frame)) * 0.3) // Apply envelope
            let envelope = Float(exp(-Double(frame) / (sampleRate * 0.3))) // Decay envelope
            channelData[frame] = sample * envelope * volume
        }
        
        return buffer
    }
}