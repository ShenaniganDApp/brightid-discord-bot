const { fontFamily } = require('tailwindcss/defaultTheme')

module.exports = {
  content: ['./app/**/*.{js,jsx,res}'],
  theme: {
    colors: {
      brightid: '#ed7a5c',
      disabled: '#fff0ed',
    },
    fontFamily: {
      poppins: ['Poppins', ...fontFamily.sans],
    },
    extend: {
      colors: {
        primary: {
          400: '#00E0F3',
          500: '#00c4fd',
        },
        dark: '#333333',
      },
    },
  },
  variants: {
    width: ['responsive'],
  },

  plugins: [],
}
