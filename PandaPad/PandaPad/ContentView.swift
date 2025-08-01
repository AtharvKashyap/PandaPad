//
//  ContentView.swift
//  PandaPad
//
//  Created by Atharv Kashyap on 8/14/24.
//

import SwiftUI

struct ContentView: View {
    
    @State var vm = ViewModel()
    @State var isSymbolAnimating = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            // Add the PandaBg image as the background
            pandaBackground
            
            VStack(spacing: 16) {
                Text("Panda Friend")
                    .font(.custom("GoodDog Cool", size: 50))
                    .foregroundColor(.white)
                
                overlayView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                
                Spacer()
                
                switch vm.state {
                case .recordingSpeech:
                    cancelRecordingButton
                        .padding(.bottom, bottomPadding())
                    
                case .processingSpeech, .playingSpeech:
                    cancelButton
                        .padding(.bottom, bottomPadding())
                    
                default: EmptyView()
                }
                
                if case let .error(error) = vm.state {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Panda background image that stays behind other views
    var pandaBackground: some View {
        Image("AppBg")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .zIndex(-1)
    }
    
    @ViewBuilder
    var overlayView: some View {
        VStack {
            switch vm.state {
            case .idle, .error:
                startCaptureButton
            case .recordingSpeech:
                pandaImage("PandaLook", text: "Panda is listening...")
            case .processingSpeech:
                pandaImage("PandaNotes", text: "Panda is thinking...")
            case .playingSpeech:
                pandaImage("PandaSpeak", text: "Panda is speaking...")
            }
        }
    }
    
    // A reusable view that ensures consistent size and alignment for the Panda images
    func pandaImage(_ imageName: String, text: String) -> some View {
        VStack {
            Spacer()
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize(), height: imageSize()) // Adjust size based on device
                .animation(.easeInOut, value: isSymbolAnimating)
                .onAppear { isSymbolAnimating = true }
                .onDisappear { isSymbolAnimating = false }
            
            Text(text)
                .font(.custom("GoodDog Plain", size: fontSize()))
                .foregroundColor(.white)
                .bold()
                .padding(.top, 10)
        }
    }
    
    var startCaptureButton: some View {
        VStack {
            Button {
                vm.startCaptureAudio()
            } label: {
                Image("PandaBamboo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize(), height: imageSize()) // Adjust size based on device
                    .animation(.smooth, value: isSymbolAnimating)
                    .onAppear { isSymbolAnimating = true }
                    .onDisappear { isSymbolAnimating = false }
            }
            .buttonStyle(.borderless)
        }
    }
    
    var cancelRecordingButton: some View {
        Button(role: .destructive) {
            vm.cancelRecording()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 50))
                .bold()
        }.buttonStyle(.borderless)
    }
    
    var cancelButton: some View {
        Button(role: .destructive) {
            vm.cancelProcessingTask()
        } label: {
            Image(systemName: "stop.circle.fill")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.red)
                .bold()
                .font(.system(size: 50))
        }.buttonStyle(.borderless)
    }
    
    // Adjust the image size based on the device type
    func imageSize() -> CGFloat {
        return horizontalSizeClass == .compact ? 256 : 300
    }
    
    // Adjust the font size based on the device type
    func fontSize() -> CGFloat {
        return horizontalSizeClass == .compact ? 45 : 60
    }
    
    // Adjust the bottom padding based on the device type
    func bottomPadding() -> CGFloat {
        return horizontalSizeClass == .compact ? 30 : 60
    }
}

#Preview("Idle") {
    ContentView()
}

#Preview("Recording Speech") {
    let vm = ViewModel()
    vm.state = .recordingSpeech
    vm.audioPower = 0.2
    return ContentView(vm: vm)
}

#Preview("Processing Speech") {
    let vm = ViewModel()
    vm.state = .processingSpeech
    return ContentView(vm: vm)
}

#Preview("Playing Speech") {
    let vm = ViewModel()
    vm.state = .playingSpeech
    vm.audioPower = 0.3
    return ContentView(vm: vm)
}

#Preview("Error") {
    let vm = ViewModel()
    vm.state = .error("An error has occurred" as! Error)
    return ContentView(vm: vm)
}
