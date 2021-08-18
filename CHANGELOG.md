
<a name="unreleased"></a>

## unreleased

> 2021-08-18

### :art: structure/code formating
 
- [9be469a](https://github.com/tami5/sql.nvim/commit/9be469a1e3480cb0a90865de313289986f8a5044): update changelog item format
 
- [2d24f86](https://github.com/tami5/sql.nvim/commit/2d24f865daf5ec9931ceff84a0c5e5a8da87eb39): update changelog item format ([#81](https://github.com/tami5/sql.nvim/issues/81))

### :sparkles: Features
 
<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/5944a91d05f34f1d36ef33a62344cfc301fc49b4" >5944a91</a>: table each and map accept function as first argument (<a href="https://github.com/tami5/sql.nvim/issues/97">#97</a>)</summary>

still compatible with query as first argument ✅  

Examples:

```lua
tbl:each(function(row) .. end) -- execute a function on all table rows
tbl:each(function(row) .. end, {...} ) -- execute a function on all table rows match the query
-- map work the same way, but return transformed table
```
</details></dd></dl>

 
<dl><dd><details><summary><a href="https://github.com/tami5/sql.nvim/commit/88f14bf3148c8c31c4ba17818d80eedc33cc9f12" >88f14bf</a>: auto changelog ([#80](https://github.com/tami5/sql.nvim/issues/80))</summary>

Here goes nothing 🤞. Please CI don't fail me.
</details></dd></dl>


