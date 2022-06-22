const { fontFamily } = require('tailwindcss/defaultTheme')

module.exports = {
  content: ['./app/**/*.{js,jsx,res}'],
  theme: {
    fontFamily: {
      poppins: ['Poppins', ...fontFamily.sans],
    },
    extend: {
      backgroundImage: {
        discordLogo: "url('~/assets/discord_logo.png')",
      },
      colors: {
        primary: {
          400: '#00E0F3',
          500: '#00c4fd',
        },
        dark: '#333333',
        brightid: '#ed7a5c',
        disabled: '#fff0ed',
      },
    },
  },
  variants: {
    width: ['responsive'],
  },

  plugins: [],
}
