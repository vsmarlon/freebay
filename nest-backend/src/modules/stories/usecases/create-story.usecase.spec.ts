import { parseStoryTextBlocks } from "../dtos/stories.dto";

describe("parseStoryTextBlocks", () => {
  it("validates and orders text blocks at the multipart boundary", () => {
    const result = parseStoryTextBlocks(
      JSON.stringify([
        {
          id: "second",
          text: " B ",
          x: 0.5,
          y: 0.5,
          scale: 1,
          rotation: 0,
          color: 0xffffffff,
          style: "strong",
          zIndex: 1,
        },
        {
          id: "first",
          text: "A",
          x: 0,
          y: 1,
          scale: 0.5,
          rotation: 0,
          color: 0,
          style: "classic",
          zIndex: 0,
        },
      ]),
    );

    expect("value" in result && result.value.map((block) => block.id)).toEqual([
      "first",
      "second",
    ]);
    expect("value" in result && result.value[1].text).toBe("B");
  });

  it("rejects duplicate IDs and unsupported styles", () => {
    const result = parseStoryTextBlocks([
      {
        id: "same",
        text: "A",
        x: 0.5,
        y: 0.5,
        scale: 1,
        rotation: 0,
        color: 0,
        style: "classic",
        zIndex: 0,
      },
      {
        id: "same",
        text: "B",
        x: 0.5,
        y: 0.5,
        scale: 1,
        rotation: 0,
        color: 0,
        style: "unknown",
        zIndex: 1,
      },
    ]);

    expect("error" in result).toBe(true);
  });
});
