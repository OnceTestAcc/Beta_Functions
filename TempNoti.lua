local D = {}
function D:CreateNotification(Information)
    local Info = Information

    if Info.Type == "FullScreen" then
        -- Instances:

        local AnomicVanguardRiskDisclaimer = Instance.new("ScreenGui")
        local RiskWarningHolder = Instance.new("Frame")
        local Title = Instance.new("TextLabel")
        local UICorner = Instance.new("UICorner")
        local UICorner_2 = Instance.new("UICorner")
        local RiskDescription = Instance.new("TextLabel")
        local UICorner_3 = Instance.new("UICorner")
        local ContinueButton = Instance.new("TextButton")
        local UICorner_4 = Instance.new("UICorner")
        local DontShowAgainButton = Instance.new("TextButton")
        local UICorner_5 = Instance.new("UICorner")
        local Blur = Instance.new("BlurEffect")

        --Properties:

        Blur.Parent = game.Lighting

        AnomicVanguardRiskDisclaimer.Name = "AnomicVanguardNotification"
        AnomicVanguardRiskDisclaimer.Parent = game:GetService("CoreGui")
        AnomicVanguardRiskDisclaimer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        RiskWarningHolder.Name = "RiskWarningHolder"
        RiskWarningHolder.Parent = AnomicVanguardRiskDisclaimer
        RiskWarningHolder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        RiskWarningHolder.BackgroundTransparency = 0.500
        RiskWarningHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RiskWarningHolder.BorderSizePixel = 0
        RiskWarningHolder.Position = UDim2.new(0.236073047, 0, 0.24977158, 0)
        RiskWarningHolder.Size = UDim2.new(0.527845025, 0, 0.5, 0)

        Title.Name = "Title"
        Title.Parent = RiskWarningHolder
        Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Title.BackgroundTransparency = 0.500
        Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Title.BorderSizePixel = 0
        Title.Position = UDim2.new(0.273700297, 0, 0.0276381914, 0)
        Title.Size = UDim2.new(0.451070338, 0, 0.125628144, 0)
        Title.Font = Enum.Font.Cartoon
        Title.Text = Info.Title
        Title.TextColor3 = Color3.fromRGB(255, 0, 4)
        Title.TextScaled = true
        Title.TextSize = 14.000
        Title.TextWrapped = true

        UICorner.CornerRadius = UDim.new(0.200000003, 0)
        UICorner.Parent = Title

        UICorner_2.CornerRadius = UDim.new(0.0500000007, 0)
        UICorner_2.Parent = RiskWarningHolder

        RiskDescription.Name = "RiskDescription"
        RiskDescription.Parent = RiskWarningHolder
        RiskDescription.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        RiskDescription.BackgroundTransparency = 0.500
        RiskDescription.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RiskDescription.BorderSizePixel = 0
        RiskDescription.Position = UDim2.new(0.0214067269, 0, 0.17336683, 0)
        RiskDescription.Size = UDim2.new(0.95718652, 0, 0.693467319, 0)
        RiskDescription.Font = Enum.Font.Cartoon
        RiskDescription.Text = Info.Description
        RiskDescription.TextColor3 = Color3.fromRGB(0, 234, 255)
        RiskDescription.TextScaled = true
        RiskDescription.TextSize = 14.000
        RiskDescription.TextWrapped = true

        UICorner_3.CornerRadius = UDim.new(0.100000001, 0)
        UICorner_3.Parent = RiskDescription

        ContinueButton.Name = "ContinueButton"
        ContinueButton.Parent = RiskWarningHolder
        ContinueButton.AnchorPoint = Vector2.new(0.5, 0.5)
        ContinueButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ContinueButton.BackgroundTransparency = 0.500
        ContinueButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ContinueButton.BorderSizePixel = 0
        ContinueButton.Position = UDim2.new(0.5, 0, 0.932160795, 0)
        ContinueButton.Size = UDim2.new(0.215596333, 0, 0.0904522613, 0)
        ContinueButton.Text = "Continue (Xs)"
        ContinueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ContinueButton.TextScaled = true
        ContinueButton.TextWrapped = true

        UICorner_4.CornerRadius = UDim.new(0.200000003, 0)
        UICorner_4.Parent = ContinueButton

        if Info.DontShowAgain then
            DontShowAgainButton.Name = "DontShowAgainButton"
            DontShowAgainButton.Parent = RiskWarningHolder
            DontShowAgainButton.AnchorPoint = Vector2.new(0.5, 0.5)
            DontShowAgainButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            DontShowAgainButton.BackgroundTransparency = 0.500
            DontShowAgainButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
            DontShowAgainButton.BorderSizePixel = 0
            DontShowAgainButton.Position = UDim2.new(0.870030582, 0, 0.932160795, 0)
            DontShowAgainButton.Size = UDim2.new(0.215596333, 0, 0.0552763827, 0)
            DontShowAgainButton.Text = "Don't show again"
            DontShowAgainButton.TextColor3 = Color3.fromRGB(255, 0, 4)
            DontShowAgainButton.TextScaled = true
            DontShowAgainButton.TextWrapped = true
        end

        UICorner_5.CornerRadius = UDim.new(0.200000003, 0)
        UICorner_5.Parent = DontShowAgainButton

        -- Scripts:

        if Info.Cooldown then
            local SecondsLeft = Info.Cooldown
                
            repeat
                SecondsLeft -= 1
                ContinueButton.Text = "Continue (" .. SecondsLeft .. ")"
                task.wait(1)
            until SecondsLeft == 0

            ContinueButton.Text = "Continue"
            ContinueButton.TextColor3 = Color3.fromRGB(0, 255, 0)
            ContinueButton.Size = UDim2.fromScale(0.400, 0.1)
        else
            ContinueButton.Text = "Continue"
        end

        ContinueButton.MouseButton1Click:Connect(function()
            if Info.ContinuePressed then
                AnomicVanguardRiskDisclaimer:Destroy()
                Blur:Destroy()
                Info.ContinuePressed()
            end
        end)

        if DontShowAgain then
            DontShowAgainButton.MouseButton1Click:Connect(function()
                -- WIP
            end)
        end
    end
end

return D
