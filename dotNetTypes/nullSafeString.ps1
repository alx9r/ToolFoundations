if ( $PSVersionTable.PSVersion -lt '3.0' )
{
    return
}

Add-Type @"
    public class NullsafeString : System.IEquatable<string>,System.IConvertible
    {
        public string Value = null;

        public NullsafeString() {}

        public NullsafeString(string v)
        {
            Value = v;
        }

        public override bool Equals(System.Object obj)
        {
            return Value.Equals(obj);
        }

        public override int GetHashCode()
        {
            return Value.GetHashCode();
        }

        public bool Equals(string other)
        {
            return Value.Equals(other);
        }

        public System.TypeCode GetTypeCode()
        {
            return Value.GetTypeCode();
        }

        public bool ToBoolean(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToBoolean(provider);
        }

        public byte ToByte(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToByte(provider);
        }

        public char ToChar(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToChar(provider);
        }

        public System.DateTime ToDateTime(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToDateTime(provider);
        }

        public decimal ToDecimal(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToDecimal(provider);
        }

        public double ToDouble(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToDouble(provider);
        }

        public short ToInt16(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToInt16(provider);
        }

        public int ToInt32(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToInt32(provider);
        }

        public long ToInt64(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToInt64(provider);
        }

        public sbyte ToSByte(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToSByte(provider);
        }

        public float ToSingle(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToSingle(provider);
        }

        override public System.String ToString()
        {
            return Value;
        }

        public string ToString(System.IFormatProvider provider)
        {
            return Value.ToString(provider);
        }

        public object ToType(System.Type conversionType, System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToType(conversionType, provider);
        }

        public ushort ToUInt16(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToUInt16(provider);
        }

        public uint ToUInt32(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToUInt32(provider);
        }

        public ulong ToUInt64(System.IFormatProvider provider)
        {
            return ((System.IConvertible)Value).ToUInt64(provider);
        }
    };
"@
