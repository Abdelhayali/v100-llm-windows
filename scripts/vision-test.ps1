# Sends an image to the server on port 8899 (OpenAI-style image_url) and prints the answer + speed.
param([string] $Image = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\test-image.png'), [int] $Port = 8899,
      [string] $Prompt = 'Describe this image: list every shape with its colour, and read the text exactly.')
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Image))
$body = @{
    messages = @(@{ role = 'user'; content = @(
        @{ type = 'text'; text = $Prompt },
        @{ type = 'image_url'; image_url = @{ url = "data:image/png;base64,$b64" } }
    ) })
    max_tokens = 200; temperature = 0
} | ConvertTo-Json -Depth 8
$sw = [Diagnostics.Stopwatch]::StartNew()
$r = Invoke-RestMethod "http://127.0.0.1:$Port/v1/chat/completions" -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 300
$sw.Stop()
$r.choices[0].message.content
"--- total {0:N1}s, prompt {1} tok @ {2:N0} t/s, gen {3:N1} t/s" -f $sw.Elapsed.TotalSeconds, $r.timings.prompt_n, $r.timings.prompt_per_second, $r.timings.predicted_per_second
