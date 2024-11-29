import React from "react";

const LoanForm = ({ fields, onSubmit, buttonText }) => {
  const [values, setValues] = React.useState({});

  const handleChange = (e) => {
    setValues({
      ...values,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(values);
  };

  return (
    <form onSubmit={handleSubmit}>
      {fields.map((field) => (
        <div key={field.name}>
          <label>{field.label}</label>
          <input
            type={field.type}
            name={field.name}
            onChange={handleChange}
            required
          />
        </div>
      ))}
      <button type="submit">{buttonText}</button>
    </form>
  );
};

export default LoanForm;
