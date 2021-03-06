module gfm.freeimage.freeimage;

import std.conv,
       std.string;

import derelict.freeimage.freeimage,
       derelict.util.exception;

/// The one exception type thrown in this wrapper.
/// A failing FreeImage function should <b>always</b> throw an FreeImageException.
class FreeImageException : Exception
{
    public
    {
        @safe pure nothrow this(string message, string file =__FILE__, size_t line = __LINE__, Throwable next = null)
        {
            super(message, file, line, next);
        }
    }
}

/// FreeImage library wrapper.
final class FreeImage
{
    public
    {
        /// Loads the FreeImage library and logs some information.
        /// Throws: FreeImageException on error.
        this(bool useExternalPlugins = false)
        {
            try
            {
                DerelictFI.load();
            }
            catch(DerelictException e)
            {
                throw new FreeImageException(e.msg);
            }

            //FreeImage_Initialise(useExternalPlugins ? TRUE : FALSE); // documentation says it's useless
            _libInitialized = true;
        }

        ~this()
        {
            close();
        }

        void close()
        {
            if (_libInitialized)
            {
                //FreeImage_DeInitialise(); // documentation says it's useless
                DerelictFI.unload();
                _libInitialized = false;
            }
        }

        const(char)[] getVersion()
        {
            const(char)* versionZ = FreeImage_GetVersion();
            return fromStringz(versionZ);
        }

        const(char)[] getCopyrightMessage()
        {
            const(char)* copyrightZ = FreeImage_GetCopyrightMessage();
            return fromStringz(copyrightZ);
        }
    }

    private
    {
        bool _libInitialized;
    }
}
