$guidFrag = [guid]::NewGuid().Guid.Split('-')[0]
Describe 'invoking .Dispose()' {
    class d : System.IDisposable {
        static $Disposed
        Dispose() {
            [d]::Disposed = $true
        }
    }
    Add-Type -TypeDefinition @'
	    public class e : System.IDisposable
	    {
		    public static bool Disposed;
		    public void Dispose()
		    {
			    e.Disposed = true;
		    }
	    }
'@
    foreach ( $objectType in 'PowerShell class','C# class' )
    {
    foreach ( $cleanupMethod in 'don''t collect garbage','collect garbage' )
    {
        $createObject = @{
            'PowerShell class' = {[d]::new()}
            'C# class' = { [e]::new() }
        }.$objectType
        $testDisposed = @{
            'PowerShell class' = {[d]::Disposed}
            'C# class' = {[e]::Disposed}
        }.$objectType
        $clearDisposed = @{
            'PowerShell class' = {[d]::Disposed = $false}
            'C# class' = {[e]::Disposed = $false}
        }.$objectType
        $cleanup = @{
            'don''t collect garbage' = {}
            'collect garbage' = { [gc]::Collect() }
        }.$cleanupMethod
        Context "$objectType; $cleanupMethod" {
            It 'class is IDisposable' {
                $d = . $createObject
                $d -is [System.IDisposable] | Should be $true
            }
            It 'manually invoking sets flag' {
                . $clearDisposed
                $d = . $createObject
                $d.Dispose()
                . $cleanup
                . $testDisposed | Should be $true
            }
            It 'not invoked when variable is cleared' {
                . $clearDisposed
                $d = . $createObject
                Clear-Variable d
                . $cleanup
                . $testDisposed | Should be $false
            }
            It 'not invoked when variable is removed' {
                . $clearDisposed
                $d = . $createObject
                Remove-Variable d
                . $cleanup
                . $testDisposed | Should be $false
            }
            It 'not invoked when object is never assigned to variable' {
                . $clearDisposed
                . $createObject
                . $cleanup
                . $testDisposed | Should be $false
            }
            It 'not invoked when object is piped to Out-Null' {
                . $clearDisposed
                . $createObject | Out-Null
                . $cleanup
                . $testDisposed | Should be $false
            }
            It 'not invoked when object only existed in a child scope' {
                . $clearDisposed
                { $d = . $createObject }.Invoke()
                . $cleanup
                . $testDisposed | Should be $false
            }
        }
    }
    }
}
