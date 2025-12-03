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
            "rullo_per_addominali": "rullo_per_addominali",
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
            "sollevamento_della_gambe_alla_sbarra": "sollevamento_della_gambe_alla_sbarra",
            "curl_con_manubri": "curl_con_manubri",
            "curl_con_bilanciere": "curl_con_bilanciere",
            "curl_con_presa_neutra": "curl_con_presa_neutra",
            "curl_con_barra_ez": "curl_con_barra_ez",
            "curl_concentrato_con_manubri": "curl_concentrato_con_manubri",
            "curl_per_bicipiti_ai_cavi": "curl_per_bicipiti_ai_cavi",
            "curl_alla_panca_scott": "curl_alla_panca_scott",
            "squat": "squat",
            "stacco_da_terra": "stacco_da_terra",
            "squat_frontale": "squat_frontale",
            "sled_leg_press": "sled_leg_press",
            "stacco_da_terra_con_bilanciere_esagonale": "stacco_da_terra_con_bilanciere_esagonale",
            "stacco_sumo": "stacco_sumo",
            "leg_press_orizzontale": "leg_press_orizzontale",
            "hip_thrust": "hip_thrust",
            "stacco_rumeno": "stacco_rumeno",
            "leg_extension": "leg_extension",
            "leg_curl_seduto": "leg_curl_seduto",
            "calf_raise_con_macchina": "calf_raise_con_macchina",
            "leg_curl_sdraiato": "leg_curl_sdraiato",
            "affondi_con_manubri": "affondi_con_manubri",
            "goblet_squat": "goblet_squat",
            "squat_bulgaro": "squat_bulgaro",
            "affondi": "affondi",
            "jump_squat": "jump_squat",
            "panca_piana": "panca_piana",
            "panca_con_manubri": "panca_con_manubri",
            "panca_inclinata": "panca_inclinata",
            "panca_inclinata_con_manubri": "panca_inclinata_con_manubri",
            "chest_press": "chest_press",
            "panca_declinata": "panca_declinata",
            "panca_a_presa_stretta": "panca_a_presa_stretta",
            "croci_con_manubri": "croci_con_manubri",
            "croci_ai_cavi": "croci_ai_cavi",
            "trazioni_a_presa_prona": "trazioni_a_presa_prona",
            "rematore_a_busto_flesso": "rematore_a_busto_flesso",
            "trazioni_alla_lat_machine": "trazioni_alla_lat_machine",
            "trazioni_a_presa_stretta": "trazioni_a_presa_stretta",
            "rematore_con_manubri": "rematore_con_manubri",
            "pulley": "pulley",
            "rematore_t_bar": "rematore_t_bar",
            "lento_avanti": "lento_avanti",
            "lento_avanti_con_manubri": "lento_avanti_con_manubri",
            "shrug_con_bilanciere": "shrug_con_bilanciere",
            "shrug_con_manubri": "shrug_con_manubri",
            "alzate_laterali_con_manubri": "alzate_laterali_con_manubri",
            "alzate_frontali_con_manubri": "alzate_frontali_con_manubri",
            "dip": "dip",
            "estensioni_dei_tricipiti_al_cavo_alto": "estensioni_dei_tricipiti_al_cavo_alto",
            "estensioni_dei_tricipiti_con_corda": "estensioni_dei_tricipiti_con_corda",
            "estensioni_dei_tricipiti_da_sdraiati": "estensioni_dei_tricipiti_da_sdraiati",
            "pressa_militare": "pressa_militare",
            "pressa_scattante": "pressa_scattante",
            "girata_al_petto_potente": "girata_al_petto_potente",
            "girata_al_petto": "girata_al_petto",
            "box_squat": "box_squat",
            "hack_squat": "hack_squat",
            "calf_raise_da_seduti": "calf_raise_da_seduti",
            "stacco_a_gambe_tese": "stacco_a_gambe_tese",
            "affondi_con_bilanciere": "affondi_con_bilanciere",
            "hyperextension": "hyperextension",
            "rematore_pendlay": "rematore_pendlay",
            "lat_machine_a_presa_stretta": "lat_machine_a_presa_stretta",
            "alzate_laterali_ai_cavi": "alzate_laterali_ai_cavi",
            "piegamenti_declinati": "piegamenti_declinati",
            "piegamenti_a_presa_stretta": "piegamenti_a_presa_stretta",
            "jumping_jack": "jumping_jack",
            "piegamenti_assistiti": "piegamenti_assistiti",
            "pike_push_up": "pike_push_up",
            "sforbiciata": "sforbiciata",
            "superman": "superman",
            "plank": "plank",
            "sollevamento_delle_gambe_da_sdraiati": "sollevamento_delle_gambe_da_sdraiati",
            "piedi_alla_sbarra": "piedi_alla_sbarra",
            "pistol_squat": "pistol_squat",
            "glute_ham_raise": "glute_ham_raise"
        ]
        
        return mappings[normalizedName] ?? normalizedName
    }
}
