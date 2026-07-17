import SwiftUI

struct BackgroundView: View {
  var body: some View {
    Image("Background")
      .resizable()
      .scaledToFill()
      .ignoresSafeArea()
      .overlay(Color.black.opacity(0.10).ignoresSafeArea())
  }
}

