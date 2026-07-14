const UI = {
    el(tag, className, props = {}) {
        const node = document.createElement(tag);
        if (className) node.className = className;
        Object.entries(props).forEach(([key, value]) => {
            if (key === 'text') node.textContent = value;
            else if (key === 'html') node.innerHTML = value;
            else if (key === 'dataset') {
                Object.entries(value).forEach(([k, v]) => { node.dataset[k] = v; });
            } else if (key.startsWith('on') && typeof value === 'function') {
                node.addEventListener(key.slice(2).toLowerCase(), value);
            } else {
                node.setAttribute(key, value);
            }
        });
        return node;
    },

    input(className, attrs = {}) {
        const input = this.el('input', className);
        Object.entries(attrs).forEach(([key, value]) => {
            if (value !== undefined && value !== null) input.setAttribute(key, value);
        });
        return input;
    },

    button(className, options = {}) {
        const btn = this.el('button', className, { type: options.type || 'button' });
        if (options.title) btn.title = options.title;
        if (options.icon) btn.appendChild(Icons.create(options.icon, options.iconSize || 18));
        if (options.text) btn.appendChild(document.createTextNode(options.text));
        if (options.onClick) btn.addEventListener('click', options.onClick);
        return btn;
    },

    iconButton(className, icon, options = {}) {
        return this.button(`${className} btn-icon`, {
            icon,
            iconSize: options.iconSize || 16,
            title: options.title,
            onClick: options.onClick,
        });
    },

    section(title, hint) {
        const wrap = this.el('div', 'section');
        const heading = this.el('h3', '', { text: title });
        wrap.appendChild(heading);
        if (hint) wrap.appendChild(this.el('p', 'hint', { text: hint }));
        return wrap;
    },

    toggle(checked, onChange) {
        const label = this.el('label', 'toggle', { title: 'Aktiv' });
        const input = this.input('', { type: 'checkbox' });
        input.checked = checked;
        input.addEventListener('change', () => onChange(input.checked));
        const slider = this.el('span', 'slider');
        label.appendChild(input);
        label.appendChild(slider);
        return { el: label, getValue: () => input.checked, setValue: (v) => { input.checked = v; } };
    },

    dropdown(options) {
        const {
            items,
            value,
            onChange,
            className = '',
            placeholder = 'Auswählen',
        } = options;

        let current = value !== undefined ? value : (items[0]?.value ?? '');
        const root = UI.el('div', `dropdown ${className}`.trim());
        const trigger = UI.el('button', 'dropdown-trigger', { type: 'button' });
        const label = UI.el('span', 'dropdown-label');
        const chevron = Icons.create('chevron', 16);
        chevron.classList.add('dropdown-chevron');
        const menu = UI.el('div', 'dropdown-menu');

        const getLabel = (val) => {
            if (val === '' || val === undefined || val === null) return placeholder;
            return items.find((i) => i.value === val)?.label ?? placeholder;
        };

        const renderLabel = () => {
            label.textContent = getLabel(current);
            label.classList.toggle('is-placeholder', current === '' || current === undefined || current === null);
        };

        const close = () => {
            root.classList.remove('open');
        };

        const open = () => {
            document.querySelectorAll('.dropdown.open').forEach((d) => {
                if (d !== root) d.classList.remove('open');
            });
            root.classList.add('open');
        };

        const setValue = (val, silent) => {
            current = val;
            renderLabel();
            menu.querySelectorAll('.dropdown-item').forEach((item) => {
                item.classList.toggle('selected', item.dataset.value === val);
            });
            if (!silent && onChange) onChange(val);
        };

        items.forEach((item) => {
            const option = UI.el('button', 'dropdown-item', {
                type: 'button',
                dataset: { value: item.value },
                text: item.label,
            });
            if (item.value === current && current !== '') option.classList.add('selected');
            option.addEventListener('click', (e) => {
                e.stopPropagation();
                setValue(item.value);
                close();
            });
            menu.appendChild(option);
        });

        trigger.appendChild(label);
        trigger.appendChild(chevron);
        trigger.addEventListener('click', (e) => {
            e.stopPropagation();
            root.classList.contains('open') ? close() : open();
        });

        root.appendChild(trigger);
        root.appendChild(menu);
        renderLabel();

        return {
            el: root,
            getValue: () => current,
            setValue,
            close,
        };
    },
};

const CustomScrollbar = {
    attach(viewport, track, thumb) {
        let dragging = false;
        let dragStartY = 0;
        let dragStartScroll = 0;

        const update = () => {
            const contentHeight = viewport.scrollHeight;
            const viewHeight = viewport.clientHeight;

            if (contentHeight <= viewHeight + 1) {
                track.classList.add('hidden');
                return;
            }

            track.classList.remove('hidden');
            const ratio = viewHeight / contentHeight;
            const thumbHeight = Math.max(36, viewHeight * ratio);
            const maxThumbTop = viewHeight - thumbHeight;
            const scrollRatio = viewport.scrollTop / (contentHeight - viewHeight);
            const thumbTop = maxThumbTop * scrollRatio;

            thumb.style.height = `${thumbHeight}px`;
            thumb.style.transform = `translateY(${thumbTop}px)`;
        };

        viewport.addEventListener('scroll', update, { passive: true });
        window.addEventListener('resize', update);

        track.addEventListener('mousedown', (e) => {
            if (e.target === thumb) return;
            const rect = track.getBoundingClientRect();
            const thumbHeight = thumb.offsetHeight;
            const clickY = e.clientY - rect.top;
            const maxThumbTop = viewport.clientHeight - thumbHeight;
            const targetTop = Math.max(0, Math.min(maxThumbTop, clickY - thumbHeight / 2));
            const scrollRatio = maxThumbTop > 0 ? targetTop / maxThumbTop : 0;
            viewport.scrollTop = scrollRatio * (viewport.scrollHeight - viewport.clientHeight);
            update();
        });

        thumb.addEventListener('mousedown', (e) => {
            dragging = true;
            dragStartY = e.clientY;
            dragStartScroll = viewport.scrollTop;
            document.body.classList.add('scrollbar-dragging');
            e.preventDefault();
        });

        document.addEventListener('mousemove', (e) => {
            if (!dragging) return;
            const contentHeight = viewport.scrollHeight;
            const viewHeight = viewport.clientHeight;
            const thumbHeight = thumb.offsetHeight;
            const maxThumbTop = viewHeight - thumbHeight;
            const maxScroll = contentHeight - viewHeight;
            const deltaY = e.clientY - dragStartY;
            const scrollDelta = maxThumbTop > 0 ? (deltaY / maxThumbTop) * maxScroll : 0;
            viewport.scrollTop = dragStartScroll + scrollDelta;
            update();
        });

        document.addEventListener('mouseup', () => {
            dragging = false;
            document.body.classList.remove('scrollbar-dragging');
        });

        return { update };
    },
};

document.addEventListener('click', () => {
    document.querySelectorAll('.dropdown.open').forEach((d) => d.classList.remove('open'));
});
