Add-Type -ErrorAction Stop -Name PowerUtil -Namespace Windows -MemberDefinition @'

    // Member variables.
    static IntPtr _powerRequest;
    static bool _mustResetDisplayRequestToo;

    // P/Invoke function declarations.
    [DllImport("kernel32.dll")]
    static extern IntPtr PowerCreateRequest(ref POWER_REQUEST_CONTEXT Context);

    [DllImport("kernel32.dll")]
    static extern bool PowerSetRequest(IntPtr PowerRequestHandle, PowerRequestType RequestType);

    [DllImport("kernel32.dll")]
    static extern bool PowerClearRequest(IntPtr PowerRequestHandle, PowerRequestType RequestType);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true, ExactSpelling = true)]
    static extern int CloseHandle(IntPtr hObject);

    // Availablity Request Enumerations and Constants
    enum PowerRequestType
    {
        PowerRequestDisplayRequired = 0,
        PowerRequestSystemRequired,
        PowerRequestAwayModeRequired,
        PowerRequestMaximum
    }

    const int POWER_REQUEST_CONTEXT_VERSION = 0;
    const int POWER_REQUEST_CONTEXT_SIMPLE_STRING = 0x1;

    // Availablity Request Structures
    // Note:  Windows defines the POWER_REQUEST_CONTEXT structure with an
    // internal union of SimpleReasonString and Detailed information.
    // To avoid runtime interop issues, this version of
    // POWER_REQUEST_CONTEXT only supports SimpleReasonString.
    // To use the detailed information,
    // define the PowerCreateRequest function with the first
    // parameter of type POWER_REQUEST_CONTEXT_DETAILED.
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct POWER_REQUEST_CONTEXT
    {
        public UInt32 Version;
        public UInt32 Flags;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string SimpleReasonString;
    }

    /// <summary>
    /// Prevents the system from going to sleep, by default including the display.
    /// </summary>
    /// <param name="enable">
    ///   True to turn on, False to turn off. Passing True must be paired with a later call passing False.
    ///   If you pass True repeatedly, subsequent invocations take no actions and ignore the parameters.
    ///   If you pass False, the remaining paramters are ignored.
    //    If you pass False without having passed True earlier, no action is performed.
    //// </param>
    /// <param name="includeDisplay">True to also keep the display awake; defaults to True.</param>
    /// <param name="reasonString">
    ///   A string describing why the system is being kept awake; defaults to the current process' command line.
    ///   This will show in the output from `powercfg -requests` (requires elevation).
    /// </param>
    public static void StayAwake(bool enable, bool includeDisplay = true, string reasonString = null)
    {

      if (enable)
      {

        // Already enabled: quietly do nothing.
        if (_powerRequest != IntPtr.Zero) { return; }

        // Configure the reason string.
        POWER_REQUEST_CONTEXT powerRequestContext;
        powerRequestContext.Version = POWER_REQUEST_CONTEXT_VERSION;
        powerRequestContext.Flags = POWER_REQUEST_CONTEXT_SIMPLE_STRING;
        powerRequestContext.SimpleReasonString = reasonString ?? System.Environment.CommandLine; // The reason for making the power request.

        // Create the request (returns a handle).
        _powerRequest = PowerCreateRequest(ref powerRequestContext);

        // Set the request(s).
        PowerSetRequest(_powerRequest, PowerRequestType.PowerRequestSystemRequired);
        if (includeDisplay) { PowerSetRequest(_powerRequest, PowerRequestType.PowerRequestDisplayRequired); }
        _mustResetDisplayRequestToo = includeDisplay;

      }
      else
      {

        // Not previously enabled: quietly do nothing.
        if (_powerRequest == IntPtr.Zero) { return; }

        // Clear the request
        PowerClearRequest(_powerRequest, PowerRequestType.PowerRequestSystemRequired);
        if (_mustResetDisplayRequestToo) { PowerClearRequest(_powerRequest, PowerRequestType.PowerRequestDisplayRequired); }
        CloseHandle(_powerRequest);
        _powerRequest = IntPtr.Zero;

      }
  }

  // Overload that allows passing a reason string while defaulting to keeping the display awake too.
  public static void StayAwake(bool enable, string reasonString)
  {
    StayAwake(enable, false, reasonString);
  }

'@

# NOTE: It's probably a good idea to call KeepPcAwake in a try block and LetPcSleep in the finally block.
function KeepPcAwake ([switch]$KeepDisplayAwake, [string]$ReasonString="PowerShell script $PSCommandPath") {
    [Windows.PowerUtil]::StayAwake($true, $KeepDisplayAwake, $ReasonString)
}
function LetPcSleep {
    [Windows.PowerUtil]::StayAwake($false)
}
