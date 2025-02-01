---
date: 2025-01-10
title: How to get a hyperlink from the clipboard
image: images/html.jpg
tags: [svelte, frontend]
categories: [web-dev]
---

The following function can get a hyperlink from the clipboard.

```js
export async function getLinkFromClipboard(e: ClipboardEvent) {
  if (!e.clipboardData) return;

  const htmlText = e.clipboardData.getData("text/html");
  if (!htmlText) {
    return;
  }

  const parser = new DOMParser();
  const doc = parser.parseFromString(htmlText, "text/html");
  const anchor = doc.querySelector("a");
  if (!anchor) {
    return;
  }

  return anchor.href;
}
```

To use this function in Svelte, you can do something like this:

```svelte
<script>
  // ...

  let linkInput: HTMLInputElement;
  async function handlePaste(e: ClipboardEvent) {
    const url = await getLinkFromClipboard(e);
    if (url) linkInput.value = url;
    setToastState({ type: "success", message: "Updated link" });
  }
</script>

<input type="text" bind:this={linkInput} on:paste={handlePaste} />
```

