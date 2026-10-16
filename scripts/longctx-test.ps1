# Long-context "needle" test: ~N tokens of filler with one secret fact in the middle.
param([int] $Paragraphs = 1150, [int] $Port = 8899)
$topics = 'GPU memory bandwidth','tensor cores','HBM2 stacks','PCIe lanes','NVLink bridges','CUDA streams','warp scheduling','L2 cache','thermal limits','power capping'
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $Paragraphs; $i++) {
    if ($i -eq [int]($Paragraphs / 2)) { [void]$sb.AppendLine('Important note: the secret launch code for project Falcon is 7391-ORCHID-52.') }
    $t = $topics[$i % $topics.Count]
    [void]$sb.AppendLine("Section ${i}: This paragraph discusses $t in data-center accelerators. Engineers measured $t across many workloads and recorded the results in table $i for later review by the team.")
}
$prompt = $sb.ToString() + "`nQuestion: What is the secret launch code for project Falcon? Reply with the code only."
$body = @{ messages = @(@{ role = 'user'; content = $prompt }); max_tokens = 30; temperature = 0 } | ConvertTo-Json -Depth 5
$sw = [Diagnostics.Stopwatch]::StartNew()
$r = Invoke-RestMethod "http://127.0.0.1:$Port/v1/chat/completions" -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 1800
$sw.Stop()
"answer: " + $r.choices[0].message.content.Trim()
"prompt tokens: {0}, prefill {1:N0} t/s, gen {2:N1} t/s, total {3:N0}s" -f $r.timings.prompt_n, $r.timings.prompt_per_second, $r.timings.predicted_per_second, $sw.Elapsed.TotalSeconds
