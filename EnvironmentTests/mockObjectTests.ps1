$guidFrag = [guid]::NewGuid().Guid.Split('-')[0]
$typeName = "c$guidFrag"
$code = @"
	public class $typeName
	{
		bool HasBeenSet = false;
        public string Name;
		public void Set() { HasBeenSet = true; }
		public bool Test() { return HasBeenSet; }
		public void Reset() { HasBeenSet = false; }
	}
"@
Add-Type $code
Invoke-Expression "class Derived$typeName : $typeName {}"
Invoke-Expression @"
    class Mocked$typeName : $typeName {
        [bool] Test () { return `$false }
    }
"@

Describe 'Test mock object' {
    foreach ( $values in @(
            @( 'original object', { New-Object $typeName },         'normal'  ),
            @( 'derived object',  { New-Object "Derived$typeName" },'normal'  ),
            @( 'mocked object',   { New-Object "Mocked$typeName" }, 'always false')
        )
    )
    {
        $testName,$construct,$behavior = $values
        Context $testName {
            $h = @{}
            It 'create the object' {
                $h.c = & $construct
                $h.c | Should not beNullOrEmpty
            }
            It 'starts out false' {
                $h.c.Test() | Should be $false
            }
            It 'set' {
                $h.c.Set()
            }
            $expectedResult = @{
                'normal' = $true
                'always false' = $false
            }.$behavior
            It "is $expectedResult" {
                $h.c.Test() | Should be $expectedResult
            }
            It 'resets' {
                $h.c.Reset()
            }
            It 'resets to false again' {
                $h.c.Test() | Should be $false
            }
        }
    }
}
