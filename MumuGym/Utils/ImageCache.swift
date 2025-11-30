import SwiftUI
import Foundation

// MARK: - AsyncImage with Cache Support
struct CachedAsyncImage<Content, Placeholder>: View where Content: View, Placeholder: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        AsyncImage(url: url) { image in
            content(image)
        } placeholder: {
            placeholder()
        }
    }
}

// MARK: - Exercise Image View
struct ExerciseImageView: View {
    let imageUrl: String?
    let exerciseName: String
    let size: CGSize
    
    init(imageUrl: String?, exerciseName: String, size: CGSize = CGSize(width: 60, height: 60)) {
        self.imageUrl = imageUrl
        self.exerciseName = exerciseName
        self.size = size
    }
    
    var body: some View {
        // Always use local SVG images instead of remote URLs
        LocalExerciseImageView(exerciseName: exerciseName, size: size)
    }
}

// MARK: - Exercise Card with Image
struct ExerciseCardWithImage: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ExerciseImageView(
                    imageUrl: exercise.imageUrl,
                    exerciseName: exercise.name ?? "Unknown",
                    size: CGSize(width: 50, height: 50)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let targetMuscle = exercise.targetMuscle {
                        Text(targetMuscle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detailed Exercise Image View
struct DetailedExerciseImageView: View {
    let imageUrl: String?
    let exerciseName: String
    
    var body: some View {
        LocalExerciseImageView(exerciseName: exerciseName, size: CGSize(width: 100, height: 100))
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
