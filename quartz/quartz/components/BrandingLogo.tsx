import { pathToRoot } from "../util/path"
import { QuartzComponentConstructor, QuartzComponentProps } from "./types"
import { classNames } from "../util/lang"

interface BrandingOptions {
  path: string
}

export default ((options: BrandingOptions) => {
  function BrandingLogo({ fileData, displayClass }: QuartzComponentProps) {
    const baseDir = pathToRoot(fileData.slug!)
    return (
      <h2 class={classNames(displayClass, "page-title")}>
        <a href={baseDir}>
          <img src={options.path} alt="exodrifter logo" draggable="false" />
        </a>
      </h2>
    )
  }

  return BrandingLogo
}) satisfies QuartzComponentConstructor