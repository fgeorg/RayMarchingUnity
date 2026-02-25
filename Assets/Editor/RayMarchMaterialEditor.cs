using UnityEditor;
using UnityEngine;

public class RayMarchMaterialEditor : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        var marchMode        = FindProperty("_MarchMode", properties);
        var sminK            = FindProperty("_SMinKValue", properties);
        var maxSteps         = FindProperty("_MaxSteps", properties);
        var maxDist          = FindProperty("_MaxDist", properties);
        var surfDist         = FindProperty("_SurfDist", properties);
        var normalDist       = FindProperty("_NormalDist", properties);
        var stepFactor       = FindProperty("_StepFactor", properties);
        var omega            = FindProperty("_Omega", properties);
        var coarseThresh     = FindProperty("_CoarseThresh", properties);
        var overshootEps     = FindProperty("_OvershootEps", properties);
        var backfaceMode     = FindProperty("_BackfaceCullMode", properties);
        var backfaceCullMin  = FindProperty("_BackfaceCullMin", properties);
        var backfaceCullMax  = FindProperty("_BackfaceCullMax", properties);
        var backfaceThresh   = FindProperty("_BackfaceCullThreshold", properties);

        Material material = materialEditor.target as Material;

        // --- Ray March ---
        EditorGUILayout.LabelField("Ray March", EditorStyles.boldLabel);
        materialEditor.ShaderProperty(marchMode, marchMode.displayName);
        materialEditor.ShaderProperty(maxSteps, maxSteps.displayName);
        materialEditor.ShaderProperty(maxDist, maxDist.displayName);
        materialEditor.ShaderProperty(surfDist, surfDist.displayName);
        materialEditor.ShaderProperty(normalDist, normalDist.displayName);
        materialEditor.ShaderProperty(stepFactor, stepFactor.displayName);

        int marchModeIndex = (int)marchMode.floatValue;
        if (marchModeIndex == 1) // Enhanced
            materialEditor.ShaderProperty(omega, omega.displayName);
        else if (marchModeIndex == 2) // Secant
            materialEditor.ShaderProperty(coarseThresh, coarseThresh.displayName);
        else if (marchModeIndex == 3) // Binary
            materialEditor.ShaderProperty(overshootEps, overshootEps.displayName);

        EditorGUILayout.Space();

        // --- SDF ---
        EditorGUILayout.LabelField("SDF", EditorStyles.boldLabel);
        materialEditor.ShaderProperty(sminK, sminK.displayName);

        EditorGUILayout.Space();

        // --- Backface Culling ---
        EditorGUILayout.LabelField("Backface Culling", EditorStyles.boldLabel);
        materialEditor.ShaderProperty(backfaceMode, backfaceMode.displayName);

        int modeIndex = (int)backfaceMode.floatValue;
        if (modeIndex == 1) // Alpha
        {
            materialEditor.ShaderProperty(backfaceCullMin, backfaceCullMin.displayName);
            materialEditor.ShaderProperty(backfaceCullMax, backfaceCullMax.displayName);
        }
        else if (modeIndex == 2) // Discard
        {
            materialEditor.ShaderProperty(backfaceThresh, backfaceThresh.displayName);
        }

        EditorGUILayout.Space();
        materialEditor.RenderQueueField();
    }
}
