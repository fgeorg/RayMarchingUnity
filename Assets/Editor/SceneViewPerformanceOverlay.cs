using UnityEditor;
using UnityEngine;
using Unity.Profiling;

[InitializeOnLoad]
public static class SceneViewPerformanceOverlay
{
    const float UpdateInterval = 0.5f;

    static ProfilerRecorder gpuRecorder;
    static ProfilerRecorder cpuRecorder;

    static double lastUpdateTime;
    static float displayCpuMs;
    static float displayGpuMs;
    static float displayFps;

    static double sampleAccumCpu;
    static double sampleAccumGpu;
    static int sampleCount;

    static SceneViewPerformanceOverlay()
    {
        gpuRecorder = ProfilerRecorder.StartNew(ProfilerCategory.Render, "GPU Frame Time");
        cpuRecorder = ProfilerRecorder.StartNew(ProfilerCategory.Internal, "Main Thread");

        SceneView.duringSceneGui += OnSceneGUI;
    }

    static void OnSceneGUI(SceneView sceneView)
    {
        // Accumulate samples every repaint
        sampleAccumCpu += cpuRecorder.LastValue;
        sampleAccumGpu += gpuRecorder.LastValue;
        sampleCount++;

        double now = EditorApplication.timeSinceStartup;
        if (now - lastUpdateTime >= UpdateInterval && sampleCount > 0)
        {
            displayCpuMs = (float)(sampleAccumCpu / sampleCount) / 1_000_000f;
            displayGpuMs = (float)(sampleAccumGpu / sampleCount) / 1_000_000f;
            float maxMs = Mathf.Max(displayCpuMs, displayGpuMs);
            displayFps = maxMs > 0 ? 1000f / maxMs : 0;

            sampleAccumCpu = 0;
            sampleAccumGpu = 0;
            sampleCount = 0;
            lastUpdateTime = now;
        }

        Handles.BeginGUI();

        EditorGUI.DrawRect(new Rect(50, 10, 150, 65), new Color(0, 0, 0, 0.7f));

        GUIStyle style = new GUIStyle(EditorStyles.boldLabel);
        style.normal.textColor = Color.green;
        GUI.Label(new Rect(55, 15, 140, 20), $"FPS: {displayFps:F0}", style);

        style.normal.textColor = Color.white;
        GUI.Label(new Rect(55, 35, 140, 20), $"CPU: {displayCpuMs:F2} ms", style);
        GUI.Label(new Rect(55, 55, 140, 20), $"GPU: {displayGpuMs:F2} ms", style);

        Handles.EndGUI();

        sceneView.Repaint();
    }
}
