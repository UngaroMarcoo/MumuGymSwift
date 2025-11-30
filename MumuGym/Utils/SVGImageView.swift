import SwiftUI

// MARK: - Themed Exercise Image View from Assets
struct ThemedExerciseImageView: View {
    let imageName: String
    
    var body: some View {
        // SwiftUI automatically handles dark/light mode with Assets.xcassets
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Fallback to system icon
            Image(systemName: "dumbbell.fill")
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Local Exercise Image View
struct LocalExerciseImageView: View {
    let exerciseName: String
    let size: CGSize
    
    init(exerciseName: String, size: CGSize = CGSize(width: 60, height: 60)) {
        self.exerciseName = exerciseName
        self.size = size
    }
    
    private var imageFileName: String {
        // Convert exercise name to image filename
        return ExerciseImageMapper.imageFileName(for: exerciseName)
    }
    
    var body: some View {
        ThemedExerciseImageView(imageName: imageFileName)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Exercise Image Mapper
struct ExerciseImageMapper {
    static func imageFileName(for exerciseName: String) -> String {
        return svgFileName(for: exerciseName) // Use same mapping logic
    }
    
    static func svgFileName(for exerciseName: String) -> String {
        let normalizedName = exerciseName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "ì", with: "i")
            .replacingOccurrences(of: "ò", with: "o")
            .replacingOccurrences(of: "ù", with: "u")
        
        // Handle special cases and known mappings
        let mappings: [String: String] = [
            "sit_up": "sit_up",
            "crunch_ai_cavi": "crunch_ai_cavi",
            "crunch_da_seduti_alla_macchina": "crunch_da_seduti_alla_macchina",
            "crunch": "crunch",
            "rullo_per_addominali": "rullo_addominali",
            "crunch_a_bicicletta": "crunch_a_bicicletta",
            "crunch_inversi": "crunch_inversi",
            "crunch_ai_cavi_in_piedi": "crunch_ai_cavi_in_piedi",
            "crunch_ai_cavi_alti": "crunch_ai_cavi_alti",
            "piegamenti": "piegamenti",
            "slancio": "slancio",
            "strappo": "strappo",
            "rack_pull": "rack_pull",
            "tirate_al_mento": "tirate_al_mento",
            "good_morning": "good_morning",
            "hang_clean": "hang_clean",
            "muscle_up": "muscle_up",
            "pullover_con_manubri": "pullover_con_manubri",
            "face_pull": "face_pull",
            "thruster": "thruster",
            "burpees": "burpees",
            "mountain_climber": "mountain_climber",
            "torsione_russa": "torsione_russa",
            "sollevamento_della_gambe_alla_sbarra": "sollevamento_delle_gambe_alla_sbarra",
            "sollevamento_delle_gambe_da_sdraiati": "sollevamento_gambe_sdraiati",
            "piedi_alla_sbarra": "piedi_alla_sbarra",
            "pistol_squat": "pistol_squat",
            "glute_ham_raise": "glute_ham_raise"
        ]
        
        return mappings[normalizedName] ?? normalizedName
    }
}