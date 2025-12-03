import Foundation
import CoreData

struct ExerciseDataModel {
    let id: Int
    let name: String
    let category: String
    let icon: String
    let description: String
    let imageUrl: String
}

class ExerciseData {
    
    static let exercisesFromCSV = [
        ExerciseDataModel(id: 1, name: "Sit-up", category: "core", icon: "sit_up", description: "Sit-up classici", imageUrl: "sit_up"),
        ExerciseDataModel(id: 2, name: "Crunch ai Cavi", category: "core", icon: "crunch_ai_cavi", description: "Crunch con resistenza ai cavi", imageUrl: "crunch_ai_cavi"),
        ExerciseDataModel(id: 3, name: "Crunch da Seduti alla Macchina", category: "core", icon: "crunch_da_seduti_alla_macchina", description: "Crunch alla macchina da seduti", imageUrl: "crunch_da_seduti_alla_macchina"),
        ExerciseDataModel(id: 4, name: "Crunch", category: "core", icon: "crunch", description: "Crunch addominali base", imageUrl: "crunch"),
        ExerciseDataModel(id: 5, name: "Rullo per Addominali", category: "core", icon: "rullo_per_addominali", description: "Esercizio con rullo addominali", imageUrl: "rullo_per_addominali"),
        ExerciseDataModel(id: 6, name: "Crunch a Bicicletta", category: "core", icon: "crunch_a_bicicletta", description: "Crunch alternati", imageUrl: "crunch_a_bicicletta"),
        ExerciseDataModel(id: 7, name: "Crunch inversi", category: "core", icon: "crunch_inversi", description: "Crunch inversi per addome basso", imageUrl: "crunch_inversi"),
        ExerciseDataModel(id: 8, name: "Crunch ai Cavi in Piedi", category: "core", icon: "crunch_ai_cavi_in_piedi", description: "Crunch in piedi ai cavi", imageUrl: "crunch_ai_cavi_in_piedi"),
        ExerciseDataModel(id: 9, name: "Crunch ai Cavi alti", category: "core", icon: "crunch_ai_cavi_alti", description: "Crunch con carrucola alta", imageUrl: "crunch_ai_cavi_alti"),
        ExerciseDataModel(id: 10, name: "Piegamenti", category: "chest", icon: "piegamenti", description: "Push-up classici", imageUrl: "piegamenti"),
        ExerciseDataModel(id: 11, name: "Slancio", category: "fullbody", icon: "slancio", description: "Clean and jerk", imageUrl: "slancio"),
        ExerciseDataModel(id: 12, name: "Strappo", category: "fullbody", icon: "strappo", description: "Snatch olimpico", imageUrl: "strappo"),
        ExerciseDataModel(id: 13, name: "Rack Pull", category: "back", icon: "rack_pull", description: "Stacco parziale", imageUrl: "rack_pull"),
        ExerciseDataModel(id: 14, name: "Tirate al Mento", category: "shoulders", icon: "tirate_al_mento", description: "Upright row", imageUrl: "tirate_al_mento"),
        ExerciseDataModel(id: 15, name: "Good-morning", category: "back", icon: "good_morning", description: "Good morning per schiena", imageUrl: "good_morning"),
        ExerciseDataModel(id: 16, name: "Hang Clean", category: "fullbody", icon: "hang_clean", description: "Clean dalla posizione hang", imageUrl: "hang_clean"),
        ExerciseDataModel(id: 17, name: "Muscle-Up", category: "fullbody", icon: "muscle_up", description: "Muscle-up alla sbarra", imageUrl: "muscle_up"),
        ExerciseDataModel(id: 18, name: "Pullover con Manubri", category: "chest", icon: "pullover_con_manubri", description: "Pullover per petto", imageUrl: "pullover_con_manubri"),
        ExerciseDataModel(id: 19, name: "Face Pull", category: "shoulders", icon: "face_pull", description: "Face pull per deltoidi posteriori", imageUrl: "face_pull"),
        ExerciseDataModel(id: 20, name: "Thruster", category: "fullbody", icon: "thruster", description: "Squat + press", imageUrl: "thruster"),
        ExerciseDataModel(id: 21, name: "Burpees", category: "cardio", icon: "burpees", description: "Burpees completi", imageUrl: "burpees"),
        ExerciseDataModel(id: 22, name: "Mountain Climber", category: "cardio", icon: "mountain_climber", description: "Mountain climber", imageUrl: "mountain_climber"),
        ExerciseDataModel(id: 23, name: "Torsione russa", category: "core", icon: "torsione_russa", description: "Russian twist", imageUrl: "torsione_russa"),
        ExerciseDataModel(id: 24, name: "Sollevamento della Gambe alla Sbarra", category: "core", icon: "sollevamento_della_gambe_alla_sbarra", description: "Hanging leg raise", imageUrl: "sollevamento_della_gambe_alla_sbarra"),
        ExerciseDataModel(id: 25, name: "Curl con Manubri", category: "arms", icon: "curl_con_manubri", description: "Curl bicipiti con manubri", imageUrl: "curl_con_manubri"),
        ExerciseDataModel(id: 26, name: "Curl con Bilanciere", category: "arms", icon: "curl_con_bilanciere", description: "Curl bicipiti con bilanciere", imageUrl: "curl_con_bilanciere"),
        ExerciseDataModel(id: 27, name: "Curl con Presa neutra", category: "arms", icon: "curl_con_presa_neutra", description: "Hammer curl", imageUrl: "curl_con_presa_neutra"),
        ExerciseDataModel(id: 28, name: "Curl con Barra EZ", category: "arms", icon: "curl_con_barra_ez", description: "Curl con barra EZ", imageUrl: "curl_con_barra_ez"),
        ExerciseDataModel(id: 29, name: "Curl concentrato con Manubri", category: "arms", icon: "curl_concentrato_con_manubri", description: "Curl concentrato", imageUrl: "curl_concentrato_con_manubri"),
        ExerciseDataModel(id: 30, name: "Curl per Bicipiti ai Cavi", category: "arms", icon: "curl_per_bicipiti_ai_cavi", description: "Curl ai cavi", imageUrl: "curl_per_bicipiti_ai_cavi"),
        ExerciseDataModel(id: 31, name: "Curl alla Panca Scott", category: "arms", icon: "curl_alla_panca_scott", description: "Preacher curl", imageUrl: "curl_alla_panca_scott"),
        ExerciseDataModel(id: 32, name: "Squat", category: "legs", icon: "squat", description: "Squat classico", imageUrl: "squat"),
        ExerciseDataModel(id: 33, name: "Stacco da Terra", category: "legs", icon: "stacco_da_terra", description: "Deadlift classico", imageUrl: "stacco_da_terra"),
        ExerciseDataModel(id: 34, name: "Squat frontale", category: "legs", icon: "squat_frontale", description: "Front squat", imageUrl: "squat_frontale"),
        ExerciseDataModel(id: 35, name: "Sled Leg Press", category: "legs", icon: "sled_leg_press", description: "Leg press inclinata", imageUrl: "sled_leg_press"),
        ExerciseDataModel(id: 36, name: "Stacco da Terra con Bilanciere esagonale", category: "legs", icon: "stacco_da_terra_con_bilanciere_esagonale", description: "Hex bar deadlift", imageUrl: "stacco_da_terra_con_bilanciere_esagonale"),
        ExerciseDataModel(id: 37, name: "Stacco Sumo", category: "legs", icon: "stacco_sumo", description: "Sumo deadlift", imageUrl: "stacco_sumo"),
        ExerciseDataModel(id: 38, name: "Leg Press orizzontale", category: "legs", icon: "leg_press_orizzontale", description: "Leg press orizzontale", imageUrl: "leg_press_orizzontale"),
        ExerciseDataModel(id: 39, name: "Hip Thrust", category: "legs", icon: "hip_thrust", description: "Hip thrust", imageUrl: "hip_thrust"),
        ExerciseDataModel(id: 40, name: "Stacco rumeno", category: "legs", icon: "stacco_rumeno", description: "Romanian deadlift", imageUrl: "stacco_rumeno"),
        ExerciseDataModel(id: 41, name: "Leg Extension", category: "legs", icon: "leg_extension", description: "Estensioni quadricipiti", imageUrl: "leg_extension"),
        ExerciseDataModel(id: 42, name: "Leg Curl seduto", category: "legs", icon: "leg_curl_seduto", description: "Leg curl da seduti", imageUrl: "leg_curl_seduto"),
        ExerciseDataModel(id: 43, name: "Calf Raise con Macchina", category: "legs", icon: "calf_raise_con_macchina", description: "Polpacci alla macchina", imageUrl: "calf_raise_con_macchina"),
        ExerciseDataModel(id: 44, name: "Leg Curl sdraiato", category: "legs", icon: "leg_curl_sdraiato", description: "Leg curl sdraiati", imageUrl: "leg_curl_sdraiato"),
        ExerciseDataModel(id: 45, name: "Affondi con Manubri", category: "legs", icon: "affondi_con_manubri", description: "Affondi con manubri", imageUrl: "affondi_con_manubri"),
        ExerciseDataModel(id: 46, name: "Goblet Squat", category: "legs", icon: "goblet_squat", description: "Squat goblet", imageUrl: "goblet_squat"),
        ExerciseDataModel(id: 47, name: "Squat bulgaro", category: "legs", icon: "squat_bulgaro", description: "Bulgarian split squat", imageUrl: "squat_bulgaro"),
        ExerciseDataModel(id: 48, name: "Affondi", category: "legs", icon: "affondi", description: "Affondi base", imageUrl: "affondi"),
        ExerciseDataModel(id: 49, name: "Jump Squat", category: "legs", icon: "jump_squat", description: "Squat esplosivi", imageUrl: "jump_squat"),
        ExerciseDataModel(id: 50, name: "Panca Piana", category: "chest", icon: "panca_piana", description: "Bench press classica", imageUrl: "panca_piana"),
        ExerciseDataModel(id: 51, name: "Panca con Manubri", category: "chest", icon: "panca_con_manubri", description: "Panca con manubri", imageUrl: "panca_con_manubri"),
        ExerciseDataModel(id: 52, name: "Panca inclinata", category: "chest", icon: "panca_inclinata", description: "Incline bench press", imageUrl: "panca_inclinata"),
        ExerciseDataModel(id: 53, name: "Panca inclinata con Manubri", category: "chest", icon: "panca_inclinata_con_manubri", description: "Incline con manubri", imageUrl: "panca_inclinata_con_manubri"),
        ExerciseDataModel(id: 54, name: "Chest Press", category: "chest", icon: "chest_press", description: "Chest press macchina", imageUrl: "chest_press"),
        ExerciseDataModel(id: 55, name: "Panca declinata", category: "chest", icon: "panca_declinata", description: "Decline bench press", imageUrl: "panca_declinata"),
        ExerciseDataModel(id: 56, name: "Panca a Presa stretta", category: "arms", icon: "panca_a_presa_stretta", description: "Close grip bench press", imageUrl: "panca_a_presa_stretta"),
        ExerciseDataModel(id: 57, name: "Croci con Manubri", category: "chest", icon: "croci_con_manubri", description: "Dumbbell fly", imageUrl: "croci_con_manubri"),
        ExerciseDataModel(id: 58, name: "Croci ai Cavi", category: "chest", icon: "croci_ai_cavi", description: "Cable fly", imageUrl: "croci_ai_cavi"),
        ExerciseDataModel(id: 59, name: "Trazioni a Presa prona", category: "back", icon: "trazioni_a_presa_prona", description: "Pull-up", imageUrl: "trazioni_a_presa_prona"),
        ExerciseDataModel(id: 60, name: "Rematore a Busto flesso", category: "back", icon: "rematore_a_busto_flesso", description: "Bent over row", imageUrl: "rematore_a_busto_flesso"),
        ExerciseDataModel(id: 61, name: "Trazioni alla Lat Machine", category: "back", icon: "trazioni_alla_lat_machine", description: "Lat pulldown", imageUrl: "trazioni_alla_lat_machine"),
        ExerciseDataModel(id: 62, name: "Trazioni a Presa stretta", category: "back", icon: "trazioni_a_presa_stretta", description: "Chin-up", imageUrl: "trazioni_a_presa_stretta"),
        ExerciseDataModel(id: 63, name: "Rematore con Manubri", category: "back", icon: "rematore_con_manubri", description: "Dumbbell row", imageUrl: "rematore_con_manubri"),
        ExerciseDataModel(id: 64, name: "Pulley", category: "back", icon: "pulley", description: "Seated cable row", imageUrl: "pulley"),
        ExerciseDataModel(id: 65, name: "Rematore T-bar", category: "back", icon: "rematore_t_bar", description: "T-bar row", imageUrl: "rematore_t_bar"),
        ExerciseDataModel(id: 66, name: "Lento Avanti", category: "shoulders", icon: "lento_avanti", description: "Overhead press", imageUrl: "lento_avanti"),
        ExerciseDataModel(id: 67, name: "Lento Avanti con Manubri", category: "shoulders", icon: "lento_avanti_con_manubri", description: "Dumbbell shoulder press", imageUrl: "lento_avanti_con_manubri"),
        ExerciseDataModel(id: 68, name: "Shrug con Bilanciere", category: "shoulders", icon: "shrug_con_bilanciere", description: "Barbell shrug", imageUrl: "shrug_con_bilanciere"),
        ExerciseDataModel(id: 69, name: "Shrug con Manubri", category: "shoulders", icon: "shrug_con_manubri", description: "Dumbbell shrug", imageUrl: "shrug_con_manubri"),
        ExerciseDataModel(id: 70, name: "Alzate laterali con Manubri", category: "shoulders", icon: "alzate_laterali_con_manubri", description: "Lateral raise", imageUrl: "alzate_laterali_con_manubri"),
        ExerciseDataModel(id: 71, name: "Alzate frontali con Manubri", category: "shoulders", icon: "alzate_frontali_con_manubri", description: "Front raise", imageUrl: "alzate_frontali_con_manubri"),
        ExerciseDataModel(id: 72, name: "Dip", category: "arms", icon: "dip", description: "Dips alle parallele", imageUrl: "dip"),
        ExerciseDataModel(id: 73, name: "Estensioni dei Tricipiti al Cavo alto", category: "arms", icon: "estensioni_dei_tricipiti_al_cavo_alto", description: "Tricep pushdown", imageUrl: "estensioni_dei_tricipiti_al_cavo_alto"),
        ExerciseDataModel(id: 74, name: "Estensioni dei Tricipiti con Corda", category: "arms", icon: "estensioni_dei_tricipiti_con_corda", description: "Rope pushdown", imageUrl: "estensioni_dei_tricipiti_con_corda"),
        ExerciseDataModel(id: 75, name: "Estensioni dei Tricipiti da Sdraiati", category: "arms", icon: "estensioni_dei_tricipiti_da_sdraiati", description: "Skull crusher", imageUrl: "estensioni_dei_tricipiti_da_sdraiati"),
        ExerciseDataModel(id: 76, name: "Pressa militare", category: "shoulders", icon: "pressa_militare", description: "Military press", imageUrl: "pressa_militare"),
        ExerciseDataModel(id: 77, name: "Pressa scattante", category: "shoulders", icon: "pressa_scattante", description: "Push press", imageUrl: "pressa_scattante"),
        ExerciseDataModel(id: 78, name: "Girata al Petto potente", category: "fullbody", icon: "girata_al_petto_potente", description: "Power clean", imageUrl: "girata_al_petto_potente"),
        ExerciseDataModel(id: 79, name: "Girata al Petto", category: "fullbody", icon: "girata_al_petto", description: "Clean", imageUrl: "girata_al_petto"),
        ExerciseDataModel(id: 80, name: "Box Squat", category: "legs", icon: "box_squat", description: "Box squat", imageUrl: "box_squat"),
        ExerciseDataModel(id: 81, name: "Hack Squat", category: "legs", icon: "hack_squat", description: "Hack squat", imageUrl: "hack_squat"),
        ExerciseDataModel(id: 82, name: "Calf Raise da Seduti", category: "legs", icon: "calf_raise_da_seduti", description: "Seated calf raise", imageUrl: "calf_raise_da_seduti"),
        ExerciseDataModel(id: 83, name: "Stacco a Gambe tese", category: "legs", icon: "stacco_a_gambe_tese", description: "Stiff leg deadlift", imageUrl: "stacco_a_gambe_tese"),
        ExerciseDataModel(id: 84, name: "Affondi con Bilanciere", category: "legs", icon: "affondi_con_bilanciere", description: "Barbell lunge", imageUrl: "affondi_con_bilanciere"),
        ExerciseDataModel(id: 85, name: "Hyperextension", category: "back", icon: "hyperextension", description: "Back extension", imageUrl: "hyperextension"),
        ExerciseDataModel(id: 86, name: "Rematore Pendlay", category: "back", icon: "rematore_pendlay", description: "Pendlay row", imageUrl: "rematore_pendlay"),
        ExerciseDataModel(id: 87, name: "Lat Machine a Presa stretta", category: "back", icon: "lat_machine_a_presa_stretta", description: "Close grip pulldown", imageUrl: "lat_machine_a_presa_stretta"),
        ExerciseDataModel(id: 88, name: "Alzate laterali ai Cavi", category: "shoulders", icon: "alzate_laterali_ai_cavi", description: "Cable lateral raise", imageUrl: "alzate_laterali_ai_cavi"),
        ExerciseDataModel(id: 89, name: "Piegamenti declinati", category: "chest", icon: "piegamenti_declinati", description: "Decline push-up", imageUrl: "piegamenti_declinati"),
        ExerciseDataModel(id: 90, name: "Piegamenti a Presa stretta", category: "arms", icon: "piegamenti_a_presa_stretta", description: "Close grip push-up", imageUrl: "piegamenti_a_presa_stretta"),
        ExerciseDataModel(id: 91, name: "Jumping Jack", category: "cardio", icon: "jumping_jack", description: "Jumping jack", imageUrl: "jumping_jack"),
        ExerciseDataModel(id: 92, name: "Piegamenti assistiti", category: "chest", icon: "piegamenti_assistiti", description: "Incline push-up", imageUrl: "piegamenti_assistiti"),
        ExerciseDataModel(id: 93, name: "Pike Push Up", category: "shoulders", icon: "pike_push_up", description: "Pike push-up", imageUrl: "pike_push_up"),
        ExerciseDataModel(id: 94, name: "Sforbiciata", category: "core", icon: "sforbiciata", description: "Flutter kicks", imageUrl: "sforbiciata"),
        ExerciseDataModel(id: 95, name: "Superman", category: "back", icon: "superman", description: "Superman", imageUrl: "superman"),
        ExerciseDataModel(id: 96, name: "Plank", category: "core", icon: "plank", description: "Plank isometrico", imageUrl: "plank"),
        ExerciseDataModel(id: 97, name: "Sollevamento delle Gambe da Sdraiati", category: "core", icon: "sollevamento_delle_gambe_da_sdraiati", description: "Lying leg raise", imageUrl: "sollevamento_delle_gambe_da_sdraiati"),
        ExerciseDataModel(id: 98, name: "Piedi alla Sbarra", category: "core", icon: "piedi_alla_sbarra", description: "Toes to bar", imageUrl: "piedi_alla_sbarra"),
        ExerciseDataModel(id: 99, name: "Pistol Squat", category: "legs", icon: "pistol_squat", description: "Pistol squat", imageUrl: "pistol_squat"),
        ExerciseDataModel(id: 100, name: "Glute Ham Raise", category: "legs", icon: "glute_ham_raise", description: "Glute ham raise", imageUrl: "glute_ham_raise")
    ]
    
    static func seedExercises(context: NSManagedObjectContext, forceReseed: Bool = false) {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        
        print("🌱 Starting exercise seeding... forceReseed: \(forceReseed)")
        
        do {
            let existingCount = try context.count(for: request)
            print("📊 Found \(existingCount) existing exercises")
            
            if forceReseed && existingCount > 0 {
                // Delete all existing exercises
                let existingExercises = try context.fetch(request)
                for exercise in existingExercises {
                    context.delete(exercise)
                }
                try context.save()
                print("🗑️ Deleted \(existingCount) existing exercises")
            }
            
            let finalCount = try context.count(for: request)
            print("📊 Final count before seeding: \(finalCount)")
            
            if finalCount == 0 {
                print("🌱 Starting to create \(exercisesFromCSV.count) exercises...")
                for exerciseData in exercisesFromCSV {
                    let exercise = Exercise(context: context)
                    exercise.name = exerciseData.name
                    exercise.type = exerciseData.category.capitalized
                    exercise.targetMuscle = mapCategoryToMuscleGroup(exerciseData.category)
                    exercise.instructions = exerciseData.description
                    exercise.imageUrl = exerciseData.imageUrl
                }
                try context.save()
                
                // Verify the seeding worked
                let verifyCount = try context.count(for: request)
                print("✅ Seeded \(exercisesFromCSV.count) exercises successfully! Verified: \(verifyCount)")
            } else if !forceReseed {
                print("📋 Exercises already exist in database (\(finalCount) found)")
            }
        } catch {
            print("❌ Failed to seed exercises: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
        }
    }
    
    private static func mapCategoryToMuscleGroup(_ category: String) -> String {
        switch category.lowercased() {
        case "core":
            return "Core"
        case "chest":
            return "Petto"
        case "fullbody":
            return "Full Body"
        case "back":
            return "Schiena"
        case "shoulders":
            return "Spalle"
        case "arms":
            return "Braccia"
        case "legs":
            return "Gambe"
        case "cardio":
            return "Cardio"
        default:
            return "Generale"
        }
    }
}