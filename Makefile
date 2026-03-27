.PHONY: test install clean

test:
	nvim --headless -c "lua require('vibelearn').setup()" -c "qa"

install:
	@echo "Installing dependencies..."
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/lazy/plenary.nvim 2>/dev/null || true
	git clone --depth 1 https://github.com/MunifTanjim/nui.nvim ~/.local/share/nvim/lazy/nui.nvim 2>/dev/null || true
	@echo "✓ Dependencies installed"

clean:
	rm -rf ~/.local/share/nvim/lazy/plenary.nvim 2>/dev/null || true
	rm -rf ~/.local/share/nvim/lazy/nui.nvim 2>/dev/null || true
	@echo "✓ Cleaned"