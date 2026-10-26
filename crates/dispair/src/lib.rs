//! DISPaiR address tuple: compiler, interpreter, store, parser.

use alloy::primitives::Address;

/// Compiler, interpreter, store and parser address tuple.
///
/// Groups the four contract addresses that together form a complete
/// Rain interpreter deployment.
#[derive(Debug, Clone, Default)]
pub struct DISPaiR {
    pub compiler: Address,
    pub interpreter: Address,
    pub store: Address,
    pub parser: Address,
}

impl DISPaiR {
    /// Creates a new `DISPaiR` from the four component addresses.
    pub fn new(compiler: Address, interpreter: Address, store: Address, parser: Address) -> Self {
        DISPaiR {
            compiler,
            interpreter,
            store,
            parser,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new() {
        let compiler = Address::repeat_byte(0x1);
        let interpreter = Address::repeat_byte(0x2);
        let store = Address::repeat_byte(0x3);
        let parser = Address::repeat_byte(0x4);

        let dispair = DISPaiR::new(compiler, interpreter, store, parser);

        assert_eq!(dispair.compiler, compiler);
        assert_eq!(dispair.interpreter, interpreter);
        assert_eq!(dispair.store, store);
        assert_eq!(dispair.parser, parser);
    }
}
