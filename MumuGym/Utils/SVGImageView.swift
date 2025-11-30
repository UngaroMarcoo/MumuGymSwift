import SwiftUI
import WebKit

// MARK: - SVG Image View with Theme Support
struct SVGImageView: UIViewRepresentable {
    let svgFileName: String
    @Environment(\.colorScheme) var colorScheme
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let svgPath = Bundle.main.path(forResource: svgFileName, ofType: "svg", inDirectory: "Resources/ExerciseImages"),
              let svgContent = try? String(contentsOfFile: svgPath) else {
            return
        }
        
        // Modify SVG content based on theme
        let themedSVGContent = adaptSVGForTheme(svgContent: svgContent)
        
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    background: transparent;
                }
                svg {
                    width: 100%;
                    height: 100%;
                    max-width: 64px;
                    max-height: 64px;
                }
            </style>
        </head>
        <body>
            \(themedSVGContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    private func adaptSVGForTheme(svgContent: String) -> String {
        var modifiedSVG = svgContent
        
        // Define color mappings for dark/light theme
        if colorScheme == .dark {
            // Dark theme adaptations
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"#000\"", with: "fill=\"#FFFFFF\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"#000000\"", with: "fill=\"#FFFFFF\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"black\"", with: "fill=\"#FFFFFF\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"#000\"", with: "stroke=\"#FFFFFF\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"#000000\"", with: "stroke=\"#FFFFFF\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"#FFFFFF\"")
        } else {
            // Light theme adaptations
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"#fff\"", with: "fill=\"#000000\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"#ffffff\"", with: "fill=\"#000000\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "fill=\"white\"", with: "fill=\"#000000\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"#fff\"", with: "stroke=\"#000000\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"#ffffff\"", with: "stroke=\"#000000\"")
            modifiedSVG = modifiedSVG.replacingOccurrences(of: "stroke=\"white\"", with: "stroke=\"#000000\"")
        }
        
        return modifiedSVG
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
    
    private var svgFileName: String {
        // Convert exercise name to SVG filename
        return ExerciseImageMapper.svgFileName(for: exerciseName)
    }
    
    var body: some View {
        Group {
            if Bundle.main.path(forResource: svgFileName, ofType: "svg", inDirectory: "Resources/ExerciseImages") != nil {
                SVGImageView(svgFileName: svgFileName)
                    .frame(width: size.width, height: size.height)
            } else {
                // Fallback to system icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    )
                    .frame(width: size.width, height: size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Exercise Image Mapper
struct ExerciseImageMapper {
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