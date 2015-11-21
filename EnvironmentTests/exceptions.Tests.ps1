Describe 'error records' {
    Context 'throw string' {
        It 'error record contains string.' {
            try
            {
                throw 'my exception message'
            }
            catch
            {
                $threw = $true
                $_.Exception.Message | Should be 'my exception message'
            }
            $threw | Should be $true
        }
    }
}
Describe 'rethrowing exceptions' {
    Context 'rethrow' {
        function f1 {
            try
            {
                f2
            }
            catch
            {
                throw
            }
        }

        function f2 {
            throw New-Object System.ArgumentException(
                'message'
            )
        }
        It 'rethrows underlying exception.' {
            try
            {
                f1
            }
            catch [System.ArgumentException]
            {
                $threw = $true
                $_.Exception.Message | Should be 'message'
                $_.CategoryInfo.Reason | Should be 'ArgumentException'
            }
            $threw | Should be $true
        }
    }
    Context 'inner' {
        function f1
        {
            try
            {
                f2
            }
            catch
            {
                throw New-Object System.ArgumentException(
                    'message f1',
                    $_.Exception
                )
            }
        }

        function f2 {
            throw New-Object System.FormatException(
                'message f2'
            )
        }
        It 'repackaging of inner exception works.' {
            try
            {
                f1
            }
            catch
            {
                $threw = $true
                $_.Exception.Message | Should be 'message f1'
                $_.Exception.InnerException.Message | Should be 'message f2'
            }
            $threw | Should be $true
        }
    }
    Context 'inner plain throw' {
        function f1
        {
            try
            {
                f2
            }
            catch
            {
                throw New-Object System.ArgumentException(
                    'message f1',
                    $_.Exception
                )
            }
        }

        function f2 {
            throw
        }
        It 'repackaging of inner exception works.' {
            try
            {
                f1
            }
            catch
            {
                $threw = $true
                $_.Exception.Message | Should be 'message f1'
                $_.Exception.InnerException.Message | Should be 'ScriptHalted'
            }
            $threw | Should be $true
        }
    }
}
if ( $PSVersionTable.PSVersion.Major -ge 4 )
{
Describe 'script stack trace' {
    Context 'plain throw' {
        function f1 {throw}

        It 'stacktrace contains throw site.' {
            try
            {
                f1
            }
            catch
            {
                $_.ScriptStackTrace | Should match 'at f1'
            }
        }
    }
    Context 'rethrow' {
        function f1 {
            try
            {
                f2
            }
            catch
            {
                throw
            }
        }

        function f2 {
            throw New-Object System.ArgumentException(
                'message'
            )
        }
        It 'stacktrace contains both throw sites.' {
            try
            {
                f1
            }
            catch
            {
                $_.ScriptStackTrace | Should match 'at f2'
                $_.ScriptStackTrace | Should match 'at f1'
            }
        }
    }
}
}
Describe 'how pester shows deep exceptions.' {
    Context 'no module' {
        function f1 {
            f2
        }
        function f2 {
            throw
        }
        It 'shows like this (uncomment to see)' {
            # f1
        }
    }
    Context 'module' {
        $module = New-Module -Name 'moduleName' -ScriptBlock {
            function f1 {
                f2
            }
            function f2 {
                throw
            }
        }
        It 'shows like this (uncomment to see)' {
            # f1
        }
    }
}
