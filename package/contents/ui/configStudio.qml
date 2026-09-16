import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "studio" as Studio

// Plasma settings page hosting the shared studio. Plasma sets every cfg_*
// property (and its *Default) from main.xml and applies them on OK/Apply, so
// Cancel still reverts. Generated key list: keep in step with main.xml.
// Plasma 6.6 hosts config pages in a Kirigami PageRow and supplies a title.
Kirigami.Page {
    id: root
    padding: 0
    implicitWidth: Kirigami.Units.gridUnit * 60
    implicitHeight: Kirigami.Units.gridUnit * 40

    property string cfg_customVisualizer
    property string cfg_customVisualizerDefault
    property string cfg_customVisualizers
    property string cfg_customVisualizersDefault
    property string cfg_customProgressBar
    property string cfg_customProgressBarDefault
    property string cfg_customProgressBars
    property string cfg_customProgressBarsDefault
    property int cfg_visualizerType
    property int cfg_visualizerTypeDefault
    property real cfg_wheelSeekSeconds
    property real cfg_wheelSeekSecondsDefault
    property bool cfg_seekHover
    property bool cfg_seekHoverDefault
    property bool cfg_seekGestures
    property bool cfg_seekGesturesDefault
    property bool cfg_reactiveProgress
    property bool cfg_reactiveProgressDefault
    property bool cfg_showChapters
    property bool cfg_showChaptersDefault
    property int cfg_progressBarStyle
    property int cfg_progressBarStyleDefault
    property int cfg_numBars
    property int cfg_numBarsDefault
    property int cfg_sensitivity
    property int cfg_sensitivityDefault
    property int cfg_framerate
    property int cfg_framerateDefault
    property real cfg_noiseReduction
    property real cfg_noiseReductionDefault
    property string cfg_inputSource
    property string cfg_inputSourceDefault
    property int cfg_lowCutoff
    property int cfg_lowCutoffDefault
    property int cfg_highCutoff
    property int cfg_highCutoffDefault
    property string cfg_frequencyScale
    property string cfg_frequencyScaleDefault
    property real cfg_bassWeight
    property real cfg_bassWeightDefault
    property real cfg_trebleWeight
    property real cfg_trebleWeightDefault
    property int cfg_silenceDecay
    property int cfg_silenceDecayDefault
    property string cfg_inputMethod
    property string cfg_inputMethodDefault
    property bool cfg_showMpris
    property bool cfg_showMprisDefault
    property bool cfg_alwaysVisible
    property bool cfg_alwaysVisibleDefault
    property bool cfg_useSystemAccent
    property bool cfg_useSystemAccentDefault
    property string cfg_customColor
    property string cfg_customColorDefault
    property real cfg_lineWidth
    property real cfg_lineWidthDefault
    property bool cfg_fillWave
    property bool cfg_fillWaveDefault
    property bool cfg_showBg
    property bool cfg_showBgDefault
    property string cfg_bgColor
    property string cfg_bgColorDefault
    property real cfg_bgRadius
    property real cfg_bgRadiusDefault
    property bool cfg_glowWave
    property bool cfg_glowWaveDefault
    property bool cfg_useSystemText
    property bool cfg_useSystemTextDefault
    property string cfg_customTextColor
    property string cfg_customTextColorDefault
    property string cfg_controlsColorSource
    property string cfg_controlsColorSourceDefault
    property string cfg_progressColorSource
    property string cfg_progressColorSourceDefault
    property string cfg_customProgressColor
    property string cfg_customProgressColorDefault
    property bool cfg_useSystemControls
    property bool cfg_useSystemControlsDefault
    property string cfg_customControlColor
    property string cfg_customControlColorDefault
    property bool cfg_useSystemDockBg
    property bool cfg_useSystemDockBgDefault
    property string cfg_customDockBgColor
    property string cfg_customDockBgColorDefault
    property bool cfg_artBg
    property bool cfg_artBgDefault
    property real cfg_artBgDim
    property real cfg_artBgDimDefault
    property real cfg_artBgBlur
    property real cfg_artBgBlurDefault
    property real cfg_artBgTransparency
    property real cfg_artBgTransparencyDefault
    property bool cfg_showArtThumb
    property bool cfg_showArtThumbDefault
    property bool cfg_artBgKeepThumb
    property bool cfg_artBgKeepThumbDefault
    property string cfg_layoutMode
    property string cfg_layoutModeDefault
    property bool cfg_autoPillInPanel
    property bool cfg_autoPillInPanelDefault
    property string cfg_pillContent
    property string cfg_pillContentDefault
    property bool cfg_pillArt
    property bool cfg_pillArtDefault
    property string cfg_pillEq
    property string cfg_pillEqDefault
    property string cfg_pillProgress
    property string cfg_pillProgressDefault
    property string cfg_pillControls
    property string cfg_pillControlsDefault
    property int cfg_pillMaxWidth
    property int cfg_pillMaxWidthDefault
    property string cfg_pillClick
    property string cfg_pillClickDefault
    property string cfg_posterAlign
    property string cfg_posterAlignDefault
    property int cfg_posterLines
    property int cfg_posterLinesDefault
    property bool cfg_posterVizBehind
    property bool cfg_posterVizBehindDefault
    property real cfg_posterVizOpacity
    property real cfg_posterVizOpacityDefault
    property bool cfg_posterClock
    property bool cfg_posterClockDefault
    property string cfg_orbitStyle
    property string cfg_orbitStyleDefault
    property real cfg_orbitReach
    property real cfg_orbitReachDefault
    property bool cfg_orbitRotate
    property bool cfg_orbitRotateDefault
    property bool cfg_orbitCoverPulse
    property bool cfg_orbitCoverPulseDefault
    property real cfg_vizVerticalOffset
    property real cfg_vizVerticalOffsetDefault
    property string cfg_vizDirection
    property string cfg_vizDirectionDefault
    property string cfg_vizColorMode
    property string cfg_vizColorModeDefault
    property string cfg_vizPalette
    property string cfg_vizPaletteDefault
    property bool cfg_hueReactive
    property bool cfg_hueReactiveDefault
    property real cfg_bloom
    property real cfg_bloomDefault
    property real cfg_ribbonCurvature
    property real cfg_ribbonCurvatureDefault
    property real cfg_ribbonFullness
    property real cfg_ribbonFullnessDefault
    property string cfg_surfaceStyle
    property string cfg_surfaceStyleDefault
    property real cfg_glassBlur
    property real cfg_glassBlurDefault
    property string cfg_glassTint
    property string cfg_glassTintDefault
    property bool cfg_compositorGlass
    property bool cfg_compositorGlassDefault
    property real cfg_glassRefraction
    property real cfg_glassRefractionDefault
    property bool cfg_glassSpecular
    property bool cfg_glassSpecularDefault
    property string cfg_cardShadow
    property string cfg_cardShadowDefault
    property bool cfg_edgeHighlight
    property bool cfg_edgeHighlightDefault
    property bool cfg_grain
    property bool cfg_grainDefault
    property bool cfg_bassPulse
    property bool cfg_bassPulseDefault
    property bool cfg_ambientGlow
    property bool cfg_ambientGlowDefault
    property real cfg_ambientGlowRadius
    property real cfg_ambientGlowRadiusDefault
    property real cfg_ambientGlowIntensity
    property real cfg_ambientGlowIntensityDefault
    property string cfg_ambientGlowMode
    property string cfg_ambientGlowModeDefault
    property string cfg_artShape
    property string cfg_artShapeDefault
    property int cfg_artScale
    property int cfg_artScaleDefault
    property string cfg_artBorder
    property string cfg_artBorderDefault
    property bool cfg_artGlow
    property bool cfg_artGlowDefault
    property bool cfg_artTilt
    property bool cfg_artTiltDefault
    property bool cfg_artReflect
    property bool cfg_artReflectDefault
    property bool cfg_artGrayPaused
    property bool cfg_artGrayPausedDefault
    property string cfg_artFallback
    property string cfg_artFallbackDefault
    property string cfg_artClick
    property string cfg_artClickDefault
    property bool cfg_accentFromArt
    property bool cfg_accentFromArtDefault
    property bool cfg_autoContrast
    property bool cfg_autoContrastDefault
    property string cfg_dockStyle
    property string cfg_dockStyleDefault
    property bool cfg_showSkipButtons
    property bool cfg_showSkipButtonsDefault
    property bool cfg_showShuffleRepeat
    property bool cfg_showShuffleRepeatDefault
    property bool cfg_showTimes
    property bool cfg_showTimesDefault
    property string cfg_timeFormat
    property string cfg_timeFormatDefault
    property int cfg_titleSize
    property int cfg_titleSizeDefault
    property string cfg_textAlign
    property string cfg_textAlignDefault
    property bool cfg_showAlbum
    property bool cfg_showAlbumDefault
    property bool cfg_showSource
    property bool cfg_showSourceDefault
    property bool cfg_showPlayerSwitch
    property bool cfg_showPlayerSwitchDefault
    property bool cfg_marquee
    property bool cfg_marqueeDefault
    property bool cfg_showLyrics
    property bool cfg_showLyricsDefault
    property string cfg_lyricsFontFamily
    property string cfg_lyricsFontFamilyDefault
    property int cfg_lyricsInlineFontSize
    property int cfg_lyricsInlineFontSizeDefault
    property int cfg_lyricsFontSize
    property int cfg_lyricsFontSizeDefault
    property int cfg_lyricsFontWeight
    property int cfg_lyricsFontWeightDefault
    property int cfg_lyricsCurrentWeight
    property int cfg_lyricsCurrentWeightDefault
    property bool cfg_lyricsItalic
    property bool cfg_lyricsItalicDefault
    property real cfg_lyricsLetterSpacing
    property real cfg_lyricsLetterSpacingDefault
    property real cfg_lyricsLineHeight
    property real cfg_lyricsLineHeightDefault
    property string cfg_lyricsAlign
    property string cfg_lyricsAlignDefault
    property string cfg_lyricsHighlight
    property string cfg_lyricsHighlightDefault
    property string cfg_lyricsHighlightColor
    property string cfg_lyricsHighlightColorDefault
    property real cfg_lyricsPastOpacity
    property real cfg_lyricsPastOpacityDefault
    property real cfg_lyricsFutureOpacity
    property real cfg_lyricsFutureOpacityDefault
    property string cfg_lyricsTextStyle
    property string cfg_lyricsTextStyleDefault
    property string cfg_lyricsTextStyleColor
    property string cfg_lyricsTextStyleColorDefault
    property int cfg_lyricsLineSpacing
    property int cfg_lyricsLineSpacingDefault
    property int cfg_lyricsPadding
    property int cfg_lyricsPaddingDefault
    property int cfg_lyricsMaxWidth
    property int cfg_lyricsMaxWidthDefault
    property bool cfg_lyricsFollow
    property bool cfg_lyricsFollowDefault
    property string cfg_lyricsFollowPosition
    property string cfg_lyricsFollowPositionDefault
    property bool cfg_lyricsShowScrollbar
    property bool cfg_lyricsShowScrollbarDefault
    property bool cfg_lyricsShowHeader
    property bool cfg_lyricsShowHeaderDefault
    property int cfg_lyricsWidth
    property int cfg_lyricsWidthDefault
    property int cfg_lyricsHeight
    property int cfg_lyricsHeightDefault
    property string cfg_lyricsLanguage
    property string cfg_lyricsLanguageDefault
    property string cfg_lyricsReading
    property string cfg_lyricsReadingDefault
    property real cfg_lyricsOffset
    property real cfg_lyricsOffsetDefault
    property string cfg_hoverDetails
    property string cfg_hoverDetailsDefault
    property var cfg_detailFields
    property var cfg_detailFieldsDefault
    property bool cfg_idleText
    property bool cfg_idleTextDefault
    property bool cfg_idleAmbient
    property bool cfg_idleAmbientDefault
    property bool cfg_dimWhenPaused
    property bool cfg_dimWhenPausedDefault
    property bool cfg_fadeVizWhenPaused
    property bool cfg_fadeVizWhenPausedDefault
    property bool cfg_hoverLift
    property bool cfg_hoverLiftDefault
    property bool cfg_scrollVolume
    property bool cfg_scrollVolumeDefault
    property bool cfg_reducedMotion
    property bool cfg_reducedMotionDefault
    property bool cfg_batterySaver
    property bool cfg_batterySaverDefault
    property bool cfg_simpleRender
    property bool cfg_simpleRenderDefault
    property bool cfg_autoDailyLook
    property bool cfg_autoDailyLookDefault
    property string cfg_dailyLookApplied
    property string cfg_dailyLookAppliedDefault
    property string cfg_favoritePresets
    property string cfg_favoritePresetsDefault
    property string cfg_userPresets
    property string cfg_userPresetsDefault
    property string cfg_dockMode
    property string cfg_dockModeDefault
    property real cfg_dockMargin
    property real cfg_dockMarginDefault
    property real cfg_barHeight
    property real cfg_barHeightDefault
    property bool cfg_widthExpansion
    property bool cfg_widthExpansionDefault
    property string cfg_dockPosition
    property string cfg_dockPositionDefault

    readonly property var draft: ({
            customVisualizer: root.cfg_customVisualizer,
            customVisualizers: root.cfg_customVisualizers,
            customProgressBar: root.cfg_customProgressBar,
            customProgressBars: root.cfg_customProgressBars,
            visualizerType: root.cfg_visualizerType,
            wheelSeekSeconds: root.cfg_wheelSeekSeconds,
            seekHover: root.cfg_seekHover,
            seekGestures: root.cfg_seekGestures,
            reactiveProgress: root.cfg_reactiveProgress,
            showChapters: root.cfg_showChapters,
            progressBarStyle: root.cfg_progressBarStyle,
            numBars: root.cfg_numBars,
            sensitivity: root.cfg_sensitivity,
            framerate: root.cfg_framerate,
            noiseReduction: root.cfg_noiseReduction,
            inputMethod: root.cfg_inputMethod,
            inputSource: root.cfg_inputSource,
            lowCutoff: root.cfg_lowCutoff,
            highCutoff: root.cfg_highCutoff,
            frequencyScale: root.cfg_frequencyScale,
            bassWeight: root.cfg_bassWeight,
            trebleWeight: root.cfg_trebleWeight,
            silenceDecay: root.cfg_silenceDecay,
            showMpris: root.cfg_showMpris,
            alwaysVisible: root.cfg_alwaysVisible,
            useSystemAccent: root.cfg_useSystemAccent,
            customColor: root.cfg_customColor,
            lineWidth: root.cfg_lineWidth,
            fillWave: root.cfg_fillWave,
            showBg: root.cfg_showBg,
            bgColor: root.cfg_bgColor,
            bgRadius: root.cfg_bgRadius,
            glowWave: root.cfg_glowWave,
            useSystemText: root.cfg_useSystemText,
            customTextColor: root.cfg_customTextColor,
            controlsColorSource: root.cfg_controlsColorSource,
            progressColorSource: root.cfg_progressColorSource,
            customProgressColor: root.cfg_customProgressColor,
            useSystemControls: root.cfg_useSystemControls,
            customControlColor: root.cfg_customControlColor,
            useSystemDockBg: root.cfg_useSystemDockBg,
            customDockBgColor: root.cfg_customDockBgColor,
            artBg: root.cfg_artBg,
            artBgDim: root.cfg_artBgDim,
            artBgBlur: root.cfg_artBgBlur,
            artBgTransparency: root.cfg_artBgTransparency,
            showArtThumb: root.cfg_showArtThumb,
            artBgKeepThumb: root.cfg_artBgKeepThumb,
            layoutMode: root.cfg_layoutMode,
            autoPillInPanel: root.cfg_autoPillInPanel,
            pillContent: root.cfg_pillContent,
            pillArt: root.cfg_pillArt,
            pillEq: root.cfg_pillEq,
            pillProgress: root.cfg_pillProgress,
            pillControls: root.cfg_pillControls,
            pillMaxWidth: root.cfg_pillMaxWidth,
            pillClick: root.cfg_pillClick,
            posterAlign: root.cfg_posterAlign,
            posterLines: root.cfg_posterLines,
            posterVizBehind: root.cfg_posterVizBehind,
            posterVizOpacity: root.cfg_posterVizOpacity,
            posterClock: root.cfg_posterClock,
            orbitStyle: root.cfg_orbitStyle,
            orbitReach: root.cfg_orbitReach,
            orbitRotate: root.cfg_orbitRotate,
            orbitCoverPulse: root.cfg_orbitCoverPulse,
            vizVerticalOffset: root.cfg_vizVerticalOffset,
            vizDirection: root.cfg_vizDirection,
            vizColorMode: root.cfg_vizColorMode,
            vizPalette: root.cfg_vizPalette,
            hueReactive: root.cfg_hueReactive,
            bloom: root.cfg_bloom,
            ribbonCurvature: root.cfg_ribbonCurvature,
            ribbonFullness: root.cfg_ribbonFullness,
            surfaceStyle: root.cfg_surfaceStyle,
            glassBlur: root.cfg_glassBlur,
            glassTint: root.cfg_glassTint,
            compositorGlass: root.cfg_compositorGlass,
            glassRefraction: root.cfg_glassRefraction,
            glassSpecular: root.cfg_glassSpecular,
            cardShadow: root.cfg_cardShadow,
            edgeHighlight: root.cfg_edgeHighlight,
            grain: root.cfg_grain,
            bassPulse: root.cfg_bassPulse,
            ambientGlow: root.cfg_ambientGlow,
            ambientGlowRadius: root.cfg_ambientGlowRadius,
            ambientGlowIntensity: root.cfg_ambientGlowIntensity,
            ambientGlowMode: root.cfg_ambientGlowMode,
            artShape: root.cfg_artShape,
            artScale: root.cfg_artScale,
            artBorder: root.cfg_artBorder,
            artGlow: root.cfg_artGlow,
            artTilt: root.cfg_artTilt,
            artReflect: root.cfg_artReflect,
            artGrayPaused: root.cfg_artGrayPaused,
            artFallback: root.cfg_artFallback,
            artClick: root.cfg_artClick,
            accentFromArt: root.cfg_accentFromArt,
            autoContrast: root.cfg_autoContrast,
            dockStyle: root.cfg_dockStyle,
            showSkipButtons: root.cfg_showSkipButtons,
            showShuffleRepeat: root.cfg_showShuffleRepeat,
            showTimes: root.cfg_showTimes,
            timeFormat: root.cfg_timeFormat,
            titleSize: root.cfg_titleSize,
            textAlign: root.cfg_textAlign,
            showAlbum: root.cfg_showAlbum,
            showSource: root.cfg_showSource,
            showPlayerSwitch: root.cfg_showPlayerSwitch,
            marquee: root.cfg_marquee,
            showLyrics: root.cfg_showLyrics,
            lyricsFontFamily: root.cfg_lyricsFontFamily,
            lyricsInlineFontSize: root.cfg_lyricsInlineFontSize,
            lyricsFontSize: root.cfg_lyricsFontSize,
            lyricsFontWeight: root.cfg_lyricsFontWeight,
            lyricsCurrentWeight: root.cfg_lyricsCurrentWeight,
            lyricsItalic: root.cfg_lyricsItalic,
            lyricsLetterSpacing: root.cfg_lyricsLetterSpacing,
            lyricsLineHeight: root.cfg_lyricsLineHeight,
            lyricsAlign: root.cfg_lyricsAlign,
            lyricsHighlight: root.cfg_lyricsHighlight,
            lyricsHighlightColor: root.cfg_lyricsHighlightColor,
            lyricsPastOpacity: root.cfg_lyricsPastOpacity,
            lyricsFutureOpacity: root.cfg_lyricsFutureOpacity,
            lyricsTextStyle: root.cfg_lyricsTextStyle,
            lyricsTextStyleColor: root.cfg_lyricsTextStyleColor,
            lyricsLineSpacing: root.cfg_lyricsLineSpacing,
            lyricsPadding: root.cfg_lyricsPadding,
            lyricsMaxWidth: root.cfg_lyricsMaxWidth,
            lyricsFollow: root.cfg_lyricsFollow,
            lyricsFollowPosition: root.cfg_lyricsFollowPosition,
            lyricsShowScrollbar: root.cfg_lyricsShowScrollbar,
            lyricsShowHeader: root.cfg_lyricsShowHeader,
            lyricsWidth: root.cfg_lyricsWidth,
            lyricsHeight: root.cfg_lyricsHeight,
            lyricsLanguage: root.cfg_lyricsLanguage,
            lyricsReading: root.cfg_lyricsReading,
            lyricsOffset: root.cfg_lyricsOffset,
            hoverDetails: root.cfg_hoverDetails,
            detailFields: root.cfg_detailFields,
            idleText: root.cfg_idleText,
            idleAmbient: root.cfg_idleAmbient,
            dimWhenPaused: root.cfg_dimWhenPaused,
            fadeVizWhenPaused: root.cfg_fadeVizWhenPaused,
            hoverLift: root.cfg_hoverLift,
            scrollVolume: root.cfg_scrollVolume,
            reducedMotion: root.cfg_reducedMotion,
            batterySaver: root.cfg_batterySaver,
            simpleRender: root.cfg_simpleRender,
            autoDailyLook: root.cfg_autoDailyLook,
            dailyLookApplied: root.cfg_dailyLookApplied,
            favoritePresets: root.cfg_favoritePresets,
            userPresets: root.cfg_userPresets,
            dockMode: root.cfg_dockMode,
            dockMargin: root.cfg_dockMargin,
            barHeight: root.cfg_barHeight,
            widthExpansion: root.cfg_widthExpansion,
            dockPosition: root.cfg_dockPosition
        })
    readonly property var defaults: ({
            customVisualizer: root.cfg_customVisualizerDefault,
            customVisualizers: root.cfg_customVisualizersDefault,
            customProgressBar: root.cfg_customProgressBarDefault,
            customProgressBars: root.cfg_customProgressBarsDefault,
            visualizerType: root.cfg_visualizerTypeDefault,
            wheelSeekSeconds: root.cfg_wheelSeekSecondsDefault,
            seekHover: root.cfg_seekHoverDefault,
            seekGestures: root.cfg_seekGesturesDefault,
            reactiveProgress: root.cfg_reactiveProgressDefault,
            showChapters: root.cfg_showChaptersDefault,
            progressBarStyle: root.cfg_progressBarStyleDefault,
            numBars: root.cfg_numBarsDefault,
            sensitivity: root.cfg_sensitivityDefault,
            framerate: root.cfg_framerateDefault,
            noiseReduction: root.cfg_noiseReductionDefault,
            inputMethod: root.cfg_inputMethodDefault,
            inputSource: root.cfg_inputSourceDefault,
            lowCutoff: root.cfg_lowCutoffDefault,
            highCutoff: root.cfg_highCutoffDefault,
            frequencyScale: root.cfg_frequencyScaleDefault,
            bassWeight: root.cfg_bassWeightDefault,
            trebleWeight: root.cfg_trebleWeightDefault,
            silenceDecay: root.cfg_silenceDecayDefault,
            showMpris: root.cfg_showMprisDefault,
            alwaysVisible: root.cfg_alwaysVisibleDefault,
            useSystemAccent: root.cfg_useSystemAccentDefault,
            customColor: root.cfg_customColorDefault,
            lineWidth: root.cfg_lineWidthDefault,
            fillWave: root.cfg_fillWaveDefault,
            showBg: root.cfg_showBgDefault,
            bgColor: root.cfg_bgColorDefault,
            bgRadius: root.cfg_bgRadiusDefault,
            glowWave: root.cfg_glowWaveDefault,
            useSystemText: root.cfg_useSystemTextDefault,
            customTextColor: root.cfg_customTextColorDefault,
            controlsColorSource: root.cfg_controlsColorSourceDefault,
            progressColorSource: root.cfg_progressColorSourceDefault,
            customProgressColor: root.cfg_customProgressColorDefault,
            useSystemControls: root.cfg_useSystemControlsDefault,
            customControlColor: root.cfg_customControlColorDefault,
            useSystemDockBg: root.cfg_useSystemDockBgDefault,
            customDockBgColor: root.cfg_customDockBgColorDefault,
            artBg: root.cfg_artBgDefault,
            artBgDim: root.cfg_artBgDimDefault,
            artBgBlur: root.cfg_artBgBlurDefault,
            artBgTransparency: root.cfg_artBgTransparencyDefault,
            showArtThumb: root.cfg_showArtThumbDefault,
            artBgKeepThumb: root.cfg_artBgKeepThumbDefault,
            layoutMode: root.cfg_layoutModeDefault,
            autoPillInPanel: root.cfg_autoPillInPanelDefault,
            pillContent: root.cfg_pillContentDefault,
            pillArt: root.cfg_pillArtDefault,
            pillEq: root.cfg_pillEqDefault,
            pillProgress: root.cfg_pillProgressDefault,
            pillControls: root.cfg_pillControlsDefault,
            pillMaxWidth: root.cfg_pillMaxWidthDefault,
            pillClick: root.cfg_pillClickDefault,
            posterAlign: root.cfg_posterAlignDefault,
            posterLines: root.cfg_posterLinesDefault,
            posterVizBehind: root.cfg_posterVizBehindDefault,
            posterVizOpacity: root.cfg_posterVizOpacityDefault,
            posterClock: root.cfg_posterClockDefault,
            orbitStyle: root.cfg_orbitStyleDefault,
            orbitReach: root.cfg_orbitReachDefault,
            orbitRotate: root.cfg_orbitRotateDefault,
            orbitCoverPulse: root.cfg_orbitCoverPulseDefault,
            vizVerticalOffset: root.cfg_vizVerticalOffsetDefault,
            vizDirection: root.cfg_vizDirectionDefault,
            vizColorMode: root.cfg_vizColorModeDefault,
            vizPalette: root.cfg_vizPaletteDefault,
            hueReactive: root.cfg_hueReactiveDefault,
            bloom: root.cfg_bloomDefault,
            ribbonCurvature: root.cfg_ribbonCurvatureDefault,
            ribbonFullness: root.cfg_ribbonFullnessDefault,
            surfaceStyle: root.cfg_surfaceStyleDefault,
            glassBlur: root.cfg_glassBlurDefault,
            glassTint: root.cfg_glassTintDefault,
            compositorGlass: root.cfg_compositorGlassDefault,
            glassRefraction: root.cfg_glassRefractionDefault,
            glassSpecular: root.cfg_glassSpecularDefault,
            cardShadow: root.cfg_cardShadowDefault,
            edgeHighlight: root.cfg_edgeHighlightDefault,
            grain: root.cfg_grainDefault,
            bassPulse: root.cfg_bassPulseDefault,
            ambientGlow: root.cfg_ambientGlowDefault,
            ambientGlowRadius: root.cfg_ambientGlowRadiusDefault,
            ambientGlowIntensity: root.cfg_ambientGlowIntensityDefault,
            ambientGlowMode: root.cfg_ambientGlowModeDefault,
            artShape: root.cfg_artShapeDefault,
            artScale: root.cfg_artScaleDefault,
            artBorder: root.cfg_artBorderDefault,
            artGlow: root.cfg_artGlowDefault,
            artTilt: root.cfg_artTiltDefault,
            artReflect: root.cfg_artReflectDefault,
            artGrayPaused: root.cfg_artGrayPausedDefault,
            artFallback: root.cfg_artFallbackDefault,
            artClick: root.cfg_artClickDefault,
            accentFromArt: root.cfg_accentFromArtDefault,
            autoContrast: root.cfg_autoContrastDefault,
            dockStyle: root.cfg_dockStyleDefault,
            showSkipButtons: root.cfg_showSkipButtonsDefault,
            showShuffleRepeat: root.cfg_showShuffleRepeatDefault,
            showTimes: root.cfg_showTimesDefault,
            timeFormat: root.cfg_timeFormatDefault,
            titleSize: root.cfg_titleSizeDefault,
            textAlign: root.cfg_textAlignDefault,
            showAlbum: root.cfg_showAlbumDefault,
            showSource: root.cfg_showSourceDefault,
            showPlayerSwitch: root.cfg_showPlayerSwitchDefault,
            marquee: root.cfg_marqueeDefault,
            showLyrics: root.cfg_showLyricsDefault,
            lyricsFontFamily: root.cfg_lyricsFontFamilyDefault,
            lyricsInlineFontSize: root.cfg_lyricsInlineFontSizeDefault,
            lyricsFontSize: root.cfg_lyricsFontSizeDefault,
            lyricsFontWeight: root.cfg_lyricsFontWeightDefault,
            lyricsCurrentWeight: root.cfg_lyricsCurrentWeightDefault,
            lyricsItalic: root.cfg_lyricsItalicDefault,
            lyricsLetterSpacing: root.cfg_lyricsLetterSpacingDefault,
            lyricsLineHeight: root.cfg_lyricsLineHeightDefault,
            lyricsAlign: root.cfg_lyricsAlignDefault,
            lyricsHighlight: root.cfg_lyricsHighlightDefault,
            lyricsHighlightColor: root.cfg_lyricsHighlightColorDefault,
            lyricsPastOpacity: root.cfg_lyricsPastOpacityDefault,
            lyricsFutureOpacity: root.cfg_lyricsFutureOpacityDefault,
            lyricsTextStyle: root.cfg_lyricsTextStyleDefault,
            lyricsTextStyleColor: root.cfg_lyricsTextStyleColorDefault,
            lyricsLineSpacing: root.cfg_lyricsLineSpacingDefault,
            lyricsPadding: root.cfg_lyricsPaddingDefault,
            lyricsMaxWidth: root.cfg_lyricsMaxWidthDefault,
            lyricsFollow: root.cfg_lyricsFollowDefault,
            lyricsFollowPosition: root.cfg_lyricsFollowPositionDefault,
            lyricsShowScrollbar: root.cfg_lyricsShowScrollbarDefault,
            lyricsShowHeader: root.cfg_lyricsShowHeaderDefault,
            lyricsWidth: root.cfg_lyricsWidthDefault,
            lyricsHeight: root.cfg_lyricsHeightDefault,
            lyricsLanguage: root.cfg_lyricsLanguageDefault,
            lyricsReading: root.cfg_lyricsReadingDefault,
            lyricsOffset: root.cfg_lyricsOffsetDefault,
            hoverDetails: root.cfg_hoverDetailsDefault,
            detailFields: root.cfg_detailFieldsDefault,
            idleText: root.cfg_idleTextDefault,
            idleAmbient: root.cfg_idleAmbientDefault,
            dimWhenPaused: root.cfg_dimWhenPausedDefault,
            fadeVizWhenPaused: root.cfg_fadeVizWhenPausedDefault,
            hoverLift: root.cfg_hoverLiftDefault,
            scrollVolume: root.cfg_scrollVolumeDefault,
            reducedMotion: root.cfg_reducedMotionDefault,
            batterySaver: root.cfg_batterySaverDefault,
            simpleRender: root.cfg_simpleRenderDefault,
            autoDailyLook: root.cfg_autoDailyLookDefault,
            dailyLookApplied: root.cfg_dailyLookAppliedDefault,
            favoritePresets: root.cfg_favoritePresetsDefault,
            userPresets: root.cfg_userPresetsDefault,
            dockMode: root.cfg_dockModeDefault,
            dockMargin: root.cfg_dockMarginDefault,
            barHeight: root.cfg_barHeightDefault,
            widthExpansion: root.cfg_widthExpansionDefault,
            dockPosition: root.cfg_dockPositionDefault
        })

    property var savedDraft: null
    property var history: []
    property bool isReverting: false

    readonly property bool hasChanges: {
        if (!root.savedDraft)
            return false;
        for (const key in root.savedDraft) {
            const cur = root.draft[key];
            const base = root.savedDraft[key];
            if (cur !== base) {
                if (Array.isArray(cur) || Array.isArray(base)) {
                    if (JSON.stringify(cur) !== JSON.stringify(base))
                        return true;
                } else {
                    return true;
                }
            }
        }
        return false;
    }

    Component.onCompleted: snapshotBaseline()

    function snapshotBaseline() {
        const snap = {};
        for (const key in root.draft)
            snap[key] = root.draft[key];
        root.savedDraft = snap;
        root.history = [];
    }

    // Plasma calls this hook when Apply or OK saves the cfg_ properties.
    function saveConfig() {
        snapshotBaseline();
    }

    function discard() {
        if (root.savedDraft) {
            root.isReverting = true;
            root.assign(root.savedDraft);
            root.history = [];
            root.isReverting = false;
        }
    }

    function undo() {
        if (root.history.length > 0) {
            root.isReverting = true;
            const prev = root.history.pop();
            root.assign(prev);
            root.isReverting = false;
        } else if (root.savedDraft) {
            discard();
        }
    }

    function assign(next) {
        if (!root.isReverting) {
            const snap = {};
            for (const key in root.draft)
                snap[key] = root.draft[key];
            root.history.push(snap);
            if (root.history.length > 30)
                root.history.shift();
        }
        for (const key in next) {
            const property = "cfg_" + key;
            if (root[property] === undefined)
                continue;
            const value = next[key];
            const current = root[property];
            const same = Array.isArray(value) || Array.isArray(current) ? JSON.stringify(value) === JSON.stringify(current) : String(value) === String(current);
            if (!same)
                root[property] = value;
        }
    }

    Plasma5Support.DataSource {
        id: doctor
        property var done: null
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (doctor.done)
                doctor.done(data["stdout"] || "");
            doctor.done = null;
            disconnectSource(source);
        }
    }

    Studio.Studio {
        anchors.fill: parent
        commandSourceComponent: Component {
            Plasma5Support.DataSource {
                engine: "executable"
            }
        }
        env: "kde"
        draft: root.draft
        defaults: root.defaults
        canDiscard: root.hasChanges
        previewAccent: Kirigami.Theme.highlightColor
        diagnosticsRunner: done => {
            doctor.done = done;
            doctor.connectSource("bash '" + Qt.resolvedUrl("../code/doctor.sh").toString().replace(/^file:\/\//, "") + "'");
        }
        onEdited: next => root.assign(next)
        onDiscard: root.discard()
        onUndo: root.undo()
    }
}
